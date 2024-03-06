# Віддзеркалення хмарних пакетів Google за допомогою IDS з відкритим кодом

## Щоб продемонструвати, як дзеркалювання пакетів можна використовувати з IDS, розглянемо приклад з використанням відкритої IDS Suricata.

Один VPC з 2 підмережами, одна для дзеркальних джерел і одна для колектора
2 веб-сервери, створені з публічною IP-адресою
1 сервер колектора (IDS), створений без публічної IP-адреси з міркувань безпеки
CloudNAT увімкнено для доступу до Інтернету за потреби
Всі віртуальні машини створені в одному регіоні і зоні, з міркувань простоти і вартості

## Побудуйте мережу

### У цьому розділі ви створите VPC і створите 2 підмережі всередині цього VPC. Все це буде зроблено за допомогою команд gcloud CLI у Google Cloud Shell.

1) Щоб створити віртуальну приватну мережу, виконайте наведені нижче дії:

```sh
gcloud compute networks create dm-stamford \
--subnet-mode=custom
```

2) Додайте підмережу до VPC для віддзеркалення трафіку в `us-central1` :

```sh
gcloud compute networks subnets create dm-stamford-us-central1 \
--range=172.21.0.0/24 \
--network=dm-stamford \
--region=us-central1
```

3) Додайте підмережу до VPC для колектора в `us-central1` :

```sh
gcloud compute networks subnets create dm-stamford-us-central1-ids \
--range=172.21.1.0/24 \
--network=dm-stamford \
--region=us-central1
```

## Створення правил брандмауера та хмарного NAT

### Для виконання цієї лабораторної роботи нам знадобиться три правила брандмауера.
### Правило 1 дозволяє стандартний порт http (TCP 80) і протокол ICMP для всіх віртуальних машин з усіх джерел.
### Правило 2 дозволяє ідентифікаторам отримувати ВЕСЬ трафік з усіх джерел. Будьте обережні, щоб не надавати ВМ IDS загальнодоступну IP-адресу, як описано в наступних розділах.
### Правило 3 дозволяє "Google Cloud IAP Proxy" IP діапазон TCP порт 22 для ВСІХ ВМ, що дозволяє вам входити в ВМ по ssh через хмарну консоль

```sh
gcloud compute firewall-rules create fw-dm-stamford-allow-any-web \
--direction=INGRESS \
--priority=1000 \
--network=dm-stamford \
--action=ALLOW \
--rules=tcp:80,icmp \
--source-ranges=0.0.0.0/0
```

```sh
gcloud compute firewall-rules create fw-dm-stamford-ids-any-any \
--direction=INGRESS \
--priority=1000 \
--network=dm-stamford \
--action=ALLOW \
--rules=all \
--source-ranges=0.0.0.0/0 \
--target-tags=ids
```

```sh
gcloud compute firewall-rules create fw-dm-stamford-iapproxy \
--direction=INGRESS \
--priority=1000 \
--network=dm-stamford \
--action=ALLOW \
--rules=tcp:22,icmp \
--source-ranges=35.235.240.0/20
```

### Створення хмарного маршрутизатора

Передумовою для хмарної NAT є попереднє налаштування хмарного маршрутизатора у відповідному регіоні:

```sh
gcloud compute routers create router-stamford-nat-us-central1 \
--region=us-central1 \
--network=dm-stamford
```

### Налаштування хмарного NAT

Щоб надати доступ до Інтернету віртуальним машинам без публічної IP-адреси, необхідно створити хмарний NAT у відповідному регіоні:

```sh
gcloud compute routers nats create nat-gw-dm-stamford-us-central1 \
--router=router-stamford-nat-us-central1 \
--router-region=us-central1 \
--auto-allocate-nat-external-ips \
--nat-all-subnet-ip-ranges
```

ВМ IDS буде створено без публічної IP-адреси, щоб переконатися, що вона недоступна з Інтернету. Однак вона потребуватиме доступу до інтернету для завантаження оновлень та встановлення пакунків Suricata.

## Створення віртуальних машин

1) Створення шаблону екземпляра для веб-сервера. Цей шаблон готує сервер Ubuntu і встановлює простий веб-сервіс:

```sh
gcloud compute instance-templates create template-dm-stamford-web-us-central1 \
--region=us-central1 \
--network=dm-stamford \
--subnet=dm-stamford-us-central1 \
--machine-type=e2-small \
--image=ubuntu-1604-xenial-v20200807 \
--image-project=ubuntu-os-cloud \
--tags=webserver \
--metadata=startup-script='#! /bin/bash
  apt-get update
  apt-get install apache2 -y
  vm_hostname="$(curl -H "Metadata-Flavor:Google" \
  http://169.254.169.254/computeMetadata/v1/instance/name)"
  echo "Page served from: $vm_hostname" | \
  tee /var/www/html/index.html
  systemctl restart apache2'
```

2) Створення групи керованих екземплярів для веб-серверів. Ця команда використовує шаблон екземпляра з попереднього кроку для створення 2 веб-серверів:

```sh
gcloud compute instance-groups managed create mig-dm-stamford-web-us-central1 \
    --template=template-dm-stamford-web-us-central1 \
    --size=2 \
    --zone=us-central1-a
```

3) Створення шаблону екземпляра для віртуальної машини IDS. Цей шаблон готує сервер Ubuntu без публічної IP-адреси:

```sh
gcloud compute instance-templates create template-dm-stamford-ids-us-central1 \
--region=us-central1 \
--network=dm-stamford \
--no-address \
--subnet=dm-stamford-us-central1-ids \
--image=ubuntu-1604-xenial-v20200807 \
--image-project=ubuntu-os-cloud \
--tags=ids,webserver \
--metadata=startup-script='#! /bin/bash
  apt-get update
  apt-get install apache2 -y
  vm_hostname="$(curl -H "Metadata-Flavor:Google" \
  http://169.254.169.254/computeMetadata/v1/instance/name)"
  echo "Page served from: $vm_hostname" | \
  tee /var/www/html/index.html
  systemctl restart apache2'
```

4) Створення групи керованих екземплярів для ВМ IDS. Ця команда використовує шаблон екземпляра з попереднього кроку для створення 1 віртуальної машини, яку буде налаштовано як вашу IDS. Встановлення Suricata буде розглянуто у наступному розділі.

```sh
gcloud compute instance-groups managed create mig-dm-stamford-ids-us-central1 \
    --template=template-dm-stamford-ids-us-central1 \
    --size=1 \
    --zone=us-central1-a
```

## Створіть внутрішній load balancer

### Дзеркалення пакетів використовує внутрішній балансувальник навантаження (ILB) для перенаправлення віддзеркаленого трафіку на групу колекторів. У цьому випадку група колекторів містить одну віртуальну машину.

1) Створіть базову перевірку стану бекенд-сервісів:

```sh
gcloud compute health-checks create tcp hc-tcp-80 --port 80
```

2) Створіть групу внутрішніх служб, яка буде використовуватися для ILB:

```sh
gcloud compute backend-services create be-dm-stamford-suricata-us-central1 \
--load-balancing-scheme=INTERNAL \
--health-checks=hc-tcp-80 \
--network=dm-stamford \
--protocol=TCP \
--region=us-central1
```

3) Додайте створену групу керованих екземплярів IDS до групи служб бекенда, створеної на попередньому кроці:

```sh
gcloud compute backend-services add-backend be-dm-stamford-suricata-us-central1 \
--instance-group=mig-dm-stamford-ids-us-central1 \
--instance-group-zone=us-central1-a \
--region=us-central1
```

4) Створіть зовнішнє правило переадресації, яке діятиме як кінцевий ендпоінт:

```sh
 gcloud compute forwarding-rules create ilb-dm-stamford-suricata-ilb-us-central1 \
 --load-balancing-scheme=INTERNAL \
 --backend-service be-dm-stamford-suricata-us-central1 \
 --is-mirroring-collector \
 --network=dm-stamford \
 --region=us-central1 \
 --subnet=dm-stamford-us-central1-ids \
 --ip-protocol=TCP \
 --ports=all
```

## Встановіть IDS з відкритим кодом - Suricata

1) Натисніть на кнопку SSH вашої ВМ IDS.
2) Оновлення IDS ВМ:

```sh
sudo apt-get update -y
```

3) Встановіть залежності Suricata:

```sh
sudo apt-get install libpcre3-dbg libpcre3-dev autoconf automake libtool libpcap-dev libnet1-dev libyaml-dev zlib1g-dev libcap-ng-dev libmagic-dev libjansson-dev libjansson4 -y
```

```sh
sudo apt-get install libnspr4-dev -y
```

```sh
sudo apt-get install libnss3-dev -y
```

```sh
sudo apt-get install liblz4-dev -y
```

```sh
sudo apt install rustc cargo -y
```

4) Встановіть Suricata:

```sh
sudo add-apt-repository ppa:oisf/suricata-stable -y
```

```sh
sudo apt-get update -y
```

```sh
sudo apt-get install suricata -y
```

5) Перевіряємо Suricata:

```sh
suricata -V
```

## Налаштуйте та перегляньте Suricata

### Команди і кроки, описані в наступному розділі, також слід виконувати в SSH ВМ IDS/Suricata.

1) Зупиніть службу Suricata і створіть резервну копію файлу конфігурації за замовчуванням:

```sh
sudo systemctl stop suricata
```

```sh
sudo cp /etc/suricata/suricata.yaml /etc/suricata/suricata.backup
```

### Завантажте та замініть новий файл конфігурації Suricata та файл скорочених правил

1) Щоб скопіювати файли, виконайте наступні команди.

```sh
wget https://storage.googleapis.com/tech-academy-enablement/GCP-Packet-Mirroring-with-OpenSource-IDS/suricata.yaml
```

```sh
wget https://storage.googleapis.com/tech-academy-enablement/GCP-Packet-Mirroring-with-OpenSource-IDS/my.rules
```

```sh
sudo mkdir /etc/suricata/poc-rules
```

```sh
sudo cp my.rules /etc/suricata/poc-rules/my.rules
```

```sh
sudo cp suricata.yaml /etc/suricata/suricata.yaml
```

2) Запустіть сервіс Суріката

```sh
sudo systemctl start suricata
```

```sh
sudo systemctl restart suricata
```

## Налаштування політики дзеркального відображення пакетів

### Для цього розділу лабораторної роботи поверніться до Cloud Shell Налаштування політики дзеркалювання пакетів можна виконати однією простою командою (або за допомогою "майстра" у графічному інтерфейсі). У цій команді ви вказуєте всі 5 атрибутів, згаданих у розділі Опис дзеркалювання пакетів.

1) Налаштуйте політику дзеркального відображення пакетів, виконавши наступне в Cloud Shell:

```sh
gcloud compute packet-mirrorings create mirror-dm-stamford-web \
--collector-ilb=ilb-dm-stamford-suricata-ilb-us-central1 \
--network=dm-stamford \
--mirrored-subnets=dm-stamford-us-central1 \
--region=us-central1
```

## Протестуйте перевірку Suricata IDS та сповіщення


