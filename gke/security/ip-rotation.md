# Rotate your control plane IP

## Initiate the rotation

To initiate an IP rotation, run the following command:

```sh
gcloud container clusters update CLUSTER_NAME \
    --start-ip-rotation
```

Confirm the rotation and leave the shell open for the operation to complete.

## Recreate nodes

If you use maintenance exclusions or maintenance windows that could result in a failed rotation, manually upgrade your cluster to force node recreation:

```sh
gcloud container clusters upgrade CLUSTER_NAME \
    --location=LOCATION \
    --cluster-version=VERSION
```

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
gcloud container clusters get-credentials CLUSTER_NAME
```

## Complete the rotation

To complete the rotation, run the following command:

```sh
gcloud container clusters update CLUSTER_NAME \
    --complete-ip-rotation
```
