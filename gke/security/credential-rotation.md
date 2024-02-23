# Rotate your cluster credentials

## Check credential lifetime

We recommend that you check your credential lifetime before and after you perform a credential rotation so that you know the validity of your cluster root CA.
To check the credential lifetime for a single cluster, run the following command:

```sh
gcloud container clusters describe CLUSTER_NAME \
    --region REGION_NAME \
    --format "value(masterAuth.clusterCaCertificate)" \
    | base64 --decode \
    | openssl x509 -noout -dates
```

To check the credential lifetime for all clusters in a project, run the following command:

```sh
gcloud container clusters list --project PROJECT_ID \
    | awk 'NR>1 {print "echo; echo Validity for cluster " $1 " in location " $2 ":;\
         gcloud container clusters describe --project PROJECT_ID " $1 " --location " $2 " \
         --format \"value(masterAuth.clusterCaCertificate)\" \
         | base64 --decode | openssl x509 -noout -dates"}' \
    | bash
```

## Start the rotation

To start a credential rotation, run the following command:

```sh
gcloud container clusters update CLUSTER_NAME \
    --region REGION_NAME \
    --start-credential-rotation
```

This command creates new credentials, issues these credentials to the control plane, and configures the control plane to serve on two IP addresses: the original IP address and a new IP address.

## Recreate nodes

If you use maintenance exclusions or maintenance windows that could result in a failed rotation, manually upgrade your cluster to force node recreation:

```sh
gcloud container clusters upgrade CLUSTER_NAME \
    --location=LOCATION \
    --cluster-version=VERSION
```

## Check the progress of node pool recreation

To monitor the rotation operation, run the following command:

```sh
gcloud container operations list \
    --filter="operationType=UPGRADE_NODES AND status=RUNNING" \
    --format="value(name)"
```

To poll the operation, pass the operation ID to the following command:

```sh
gcloud container operations wait OPERATION_ID
```

## Update API clients

To update your API clients, run the following command for each client:

```sh
gcloud container clusters get-credentials CLUSTER_NAME \
    --region REGION_NAME
```

### Update Kubernetes ServiceAccount credentials

If you use static credentials for ServiceAccounts in your cluster, switch to short-lived credentials. Completing the rotation invalidates existing ServiceAccount credentials. If you don't want to use short-lived credentials, ensure that you recreate your static credentials for all ServiceAccounts in the cluster after you complete the rotation.

## Complete the rotation

After updating API clients outside the cluster, complete the rotation to configure the control plane to serve only with the new credentials and the new IP address:

```sh
gcloud container clusters update CLUSTER_NAME \
    --region=REGION_NAME \
    --complete-credential-rotation
```
