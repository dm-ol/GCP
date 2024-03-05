# Створення приватного кластера Kubernetes

## Встановіть регіон і зону

1) Встановіть регіон проекту для цієї лабораторії:

```sh
gcloud config set compute/zone us-east4-b
```

2) Створіть змінну для регіону:

```sh
export REGION=us-east4
```

3) Створіть змінну для зони:

```sh
export ZONE=us-east4-b
```

4) Створення приватного кластера

Коли ви створюєте приватний кластер, ви повинні вказати діапазон CIDR /28 для віртуальних машин, на яких запущено головні компоненти Kubernetes, і вам потрібно увімкнути IP-псевдоніми.
Далі ви створите кластер із назвою private-cluster і вкажете діапазон CIDR 172.16.0.16/28 для головних компонентів. Увімкнувши IP-псевдоніми, ви дозволите Kubernetes Engine автоматично створити для вас підмережу.

Ви створите приватний кластер за допомогою прапорців --private-cluster, --master-ipv4-cidr і --enable-ip-alias.

```sh
gcloud beta container clusters create private-cluster \
    --enable-private-nodes \
    --master-ipv4-cidr 172.16.0.16/28 \
    --enable-ip-alias \
    --create-subnetwork ""
```

## Перегляд діапазонів підмережі та вторинних адрес

1) Перелічіть підмережі у мережі за замовчуванням:

```sh
gcloud compute networks subnets list --network default
```

2) У результатах знайдіть назву підмережі, яка була автоматично створена для вашого кластера. Наприклад, gke-private-cluster-subnet-xxxxxxxxxx. Збережіть назву кластера, вона знадобиться вам на наступному кроці. `gke-private-cluster-subnet-2995c39d`

3) Тепер отримайте інформацію про автоматично створену підмережу, замінивши [SUBNET_NAME] на вашу підмережу за допомогою запуску:

```sh
gcloud compute networks subnets describe gke-private-cluster-subnet-2995c39d --region=$REGION
```

На виході ви побачите первинний діапазон адрес з назвою вашого приватного кластера GKE і вторинні діапазони

## Увімкнення головних авторизованих мереж

### На даний момент єдиними IP-адресами, які мають доступ до головного пристрою, є адреси з цих діапазонів:
Основний діапазон вашої підмережі. Це діапазон, який використовується для вузлів.
Вторинний діапазон вашої підмережі, який використовується для підмереж.
Щоб надати додатковий доступ до головного пристрою, ви повинні авторизувати вибрані діапазони адрес.

1) Створіть вихідний екземпляр, який ви будете використовувати для перевірки підключення до кластерів Kubernetes:

```sh
gcloud compute instances create source-instance --zone=$ZONE --scopes 'https://www.googleapis.com/auth/cloud-platform'
```

2) Отримати <External_IP> екземпляра-джерела за допомогою:

```sh
gcloud compute instances describe source-instance --zone=$ZONE | grep natIP
```

3) Скопіюйте адресу <nat_IP> і збережіть її, щоб використовувати на наступних кроках. `35.186.183.30`

4) Виконайте наступні дії для авторизації діапазону зовнішніх адрес, замінивши [MY_EXTERNAL_RANGE] на діапазон CIDR зовнішніх адрес з попереднього виводу (ваш діапазон CIDR - natIP/32). Якщо діапазон CIDR буде natIP/32, ми дозволимо вносити до списку одну конкретну IP-адресу:

```sh
gcloud container clusters update private-cluster \
    --enable-master-authorized-networks \
    --master-authorized-networks 35.186.183.30/32
```

5) Тепер, коли ви маєте доступ до головного вузла з різних зовнішніх адрес, ви встановите kubectl і зможете використовувати його для отримання інформації про ваш кластер. Наприклад, за допомогою kubectl можна перевірити, чи не мають ваші вузли зовнішніх IP-адрес.

6) SSH у вихідний екземпляр з:

```sh
gcloud compute ssh source-instance --zone=$ZONE
```

7) У SSH-оболонці встановіть компонент kubectl з Cloud-SDK:

```sh
sudo apt-get install kubectl
```

8) Налаштуйте доступ до кластера Kubernetes з оболонки SSH за допомогою:

```sh
export ZONE=us-east4-b
```

```sh
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
gcloud container clusters get-credentials private-cluster --zone=$ZONE
```

9) Переконайтеся, що вузли кластера не мають зовнішніх IP-адрес:

```sh
kubectl get nodes --output yaml | grep -A4 addresses
```

10) Ось ще одна команда, яку можна використати для перевірки того, що ваші вузли не мають зовнішніх IP-адрес:

```sh
kubectl get nodes --output wide
```

11) Вихід з SSH

## Створення приватного кластера, який використовує власну підмережу

### У попередньому розділі Kubernetes Engine автоматично створив для вас підмережу. У цьому розділі ви створите власну підмережу, а потім створите приватний кластер. Ваша підмережа має первинний діапазон адрес і два вторинних діапазони адрес.

1) Створіть підмережу та вторинні діапазони:

```sh
gcloud compute networks subnets create my-subnet \
    --network default \
    --range 10.0.4.0/22 \
    --enable-private-ip-google-access \
    --region=$REGION \
    --secondary-range my-svc-range=10.0.32.0/20,my-pod-range=10.4.0.0/14
```

2) Створіть приватний кластер, який використовує вашу підмережу:

```sh
gcloud beta container clusters create private-cluster2 \
    --enable-private-nodes \
    --enable-ip-alias \
    --master-ipv4-cidr 172.16.0.32/28 \
    --subnetwork my-subnet \
    --services-secondary-range-name my-svc-range \
    --cluster-secondary-range-name my-pod-range \
    --zone=$ZONE
```

3) Отримати діапазон зовнішніх адрес вихідного екземпляра:

```sh
gcloud compute instances describe source-instance --zone=$ZONE | grep natIP
```

4) Скопіюйте адресу <nat_IP> і збережіть її, щоб використовувати на наступних кроках. `35.186.183.30`

5) Виконайте наступні дії для авторизації діапазону зовнішніх адрес, замінивши [MY_EXTERNAL_RANGE] на діапазон CIDR зовнішніх адрес з попереднього виводу (ваш діапазон CIDR - natIP/32). Якщо діапазон CIDR буде natIP/32, ми дозволимо вносити до списку одну конкретну IP-адресу:

```gcloud container clusters update private-cluster2 \
    --enable-master-authorized-networks \
    --zone=$ZONE \
    --master-authorized-networks 35.186.183.30/32
```

