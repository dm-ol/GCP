# Опис об'єктів та опцій Kubernetes у маніфесті
## Приклад маніфесту неймспейсу:
```yaml
apiVersion: v1  # версія API Kubernetes
kind: Namespace  # тип обє'кту
metadata:
 name: server  # назва об'єкту
```
## Приклад маніфесту розгортання:
```yaml
apiVersion: apps/v1  # версія API Kubernetes
kind: Deployment  # тип обє'кту
metadata:
  name: nginx-deployment  # назва об'єкту
  labels:  # мітка, яка додаються до об'єкту
    app: nginx
spec:
  replicas: 3  # кількість реплік
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:  # налаштування контейнеру
     —name: nginx 
        image: nginx:1.14.2  # образ для контейнеру
        ports:  # порти контейнеру
       —containerPort: 80
```
