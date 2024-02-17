# Операції з кластером у GKE
## Створення кластеру
```sh
export my_zone=ZONE
export my_cluster=NAME
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
