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
