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
## Приклад маніфесту сервісу:
```yaml
apiVersion: v1  # версія API Kubernetes
kind: Service  # тип обє'кту
metadata:
  name: my-service  # назва об'єкту
spec:
  type: NodePort  # тип сервісу
  selector:
    app.kubernetes.io/name: MyApp
  ports:  # порти сервісу (мультипорт в нашому випадку)
    - name: http
      protocol: TCP  # протокол
      port: 80   # зовнішній порт
      targetPort: 9376  # внутріщній порт
    - name: https
      protocol: TCP   # протокол
      port: 443   # зовнішній порт
      targetPort: 9377  # внутріщній порт
```
