# Мережевий пірінг VPC

## Налаштування мережевого пірингу VPC

### Створіть власну мережу в проектах A & B

1) Поверніться до першої Cloud Shell і виконайте наступні дії, щоб створити власну мережу:

```sh
gcloud compute networks create network-a --subnet-mode custom
```

2) Створіть підмережу в межах цієї VPC і вкажіть регіон та діапазон IP-адрес, запустивши її:

```sh
gcloud compute networks subnets create network-a-subnet --network network-a \
    --range 10.0.0.0/16 --region us-east4
```

3) Створіть екземпляр віртуальної машини:

```sh
gcloud compute instances create vm-a --zone us-east4-a --network network-a --subnet network-a-subnet --machine-type e2-small
```

4) Виконайте наступні дії, щоб увімкнути SSH і icmp, оскільки вам знадобиться захищена оболонка для спілкування з віртуальними машинами під час тестування підключення:

```sh
gcloud compute firewall-rules create network-a-fw --network network-a --allow tcp:22,icmp
```

### Далі ви налаштовуєте Project-B у такий самий спосіб.

1) Поверніться до першої Cloud Shell і виконайте наступні дії, щоб створити власну мережу:

```sh
gcloud compute networks create network-b --subnet-mode custom
```

2) Створіть підмережу в межах цієї VPC і вкажіть регіон та діапазон IP-адрес, запустивши її:

```sh
gcloud compute networks subnets create network-b-subnet --network network-b \
    --range 10.8.0.0/16 --region us-east1
```

3) Створіть екземпляр віртуальної машини:

```sh
gcloud compute instances create vm-b --zone us-east1-d --network network-b --subnet network-b-subnet --machine-type e2-small
```

4) Виконайте наступні дії, щоб увімкнути SSH і icmp, оскільки вам знадобиться захищена оболонка для спілкування з віртуальними машинами під час тестування підключення:

```sh
gcloud compute firewall-rules create network-b-fw --network network-b --allow tcp:22,icmp
```

## Налаштування сеансу мережевого пірингу VPC

### Peer network-A with network-B:

Перейдіть до мережевого пірингу VPC у хмарній консолі, перейшовши до розділу `VPC Network > VPC network peering` у лівому меню. Опинившись там:

Натисніть `Create connection.`

Натисніть `Continue.`

Введіть `"peer-ab"` як Name для цієї сторони підключення.

У розділі `Your VPC network` виберіть мережу, до якої ви хочете підключитися `(network-a)`.

Установіть перемикачі для параметра `Peered VPC network` на значення `In another project`.

Вставте `Project ID` другого проєкту.

Введіть назву мережі `VPC network name` `(network-b)`.

Натисніть кнопку `Create`.


### Peer network-b with network-a

Перейдіть до мережевого пірингу VPC у хмарній консолі, перейшовши до розділу `VPC Network > VPC network peering` у лівому меню. Опинившись там:

Натисніть `Create connection.`

Натисніть `Continue.`

Введіть `"peer-ba"` як Name для цієї сторони підключення.

У розділі `Your VPC network` виберіть мережу, до якої ви хочете підключитися `(network-b)`.

Установіть перемикачі для параметра `Peered VPC network` на значення `In another project`.

Вставте `Project ID` першого проєкту.

Введіть назву мережі `VPC network name` `(network-a)`.

Натисніть кнопку `Create`.
