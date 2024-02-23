# Операції з кластером у GKE

## Створення кластеру

```sh
export my_zone=ZONE #example us-east4-c
export my_cluster=NAME #example my-cluster
```

```sh
gcloud container clusters create $my_cluster --num-nodes 3 --zone $my_zone --enable-ip-alias
```

## Модифікація кластеру

```sh
gcloud container clusters resize $my_cluster --zone $my_zone --num-nodes=4
```

## Доступ до кластеру

```sh
gcloud container clusters get-credentials $my_cluster --zone $my_zone
```

## Конфіг кластеру

```sh
nano ~/.kube/config
```

```sh
kubectl config view
```

## Replica scale

```sh
kubectl scale deployment [NAME] --replicas 10
```

## Cluster autoscaling

```sh
gcloud container clusters create  [CLUSTER NAME] --enable-autoscaling --min-nodes 5 --max-nodes 20 --zone [COMPUTE ZONE] --project [PROJECT ID]
```

```sh
gcloud container clusters update  [CLUSTER NAME] --enable-autoscaling --min-nodes 5 --max-nodes 20 --zone [COMPUTE ZONE] --node-pool [POOL NAME] --project [PROJECT ID]
```

```sh
gcloud container node-pools create  [CLUSTER NAME] --enable-autoscaling --min-nodes 15 --max-nodes 50 --zone [COMPUTE ZONE] --node-pool [POOL NAME] --project [PROJECT ID]
```

```sh
gcloud container node-pools update  [CLUSTER NAME] --enable-autoscaling --min-nodes 15 --max-nodes 50 --zone [COMPUTE ZONE] --node-pool [POOL NAME] --project [PROJECT ID]
```

temp nodes

```sh
gcloud container node-pools create ["POOL NAME"] \
--cluster=[CLUSTER NAME] --zone=[COMPUTE ZONE] \
--num-nodes "2" --node-labels=temp=true --preemptible
```

verify that the new nodes are ready:

```sh
kubectl get nodes
```

```sh
kubectl get nodes -l temp=true
```

## Control scheduling with taints and tolerations

You can use the temp=true label to apply this change across all the new nodes simultaneously:

```sh
kubectl taint node -l temp=true nodetype=preemptible:NoExecute
```

## Deployment autoscaling

```sh
kubectl autoscale deployment [DEPLOY NAME] --max 4 --min 1 --cpu-percent 1
```

and inspect the configuration of `HorizontalPodAutoscaler`

```sh
kubectl get hpa
```

or describe

```sh
kubectl describe horizontalpodautoscaler [DEPLOY NAME]
```

or config yaml manifest

```sh
kubectl get horizontalpodautoscaler [DEPLOY NAME] -o yaml
```
