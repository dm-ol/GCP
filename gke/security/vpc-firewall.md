# Налаштування брандмауерів VPC

## Створіть мережі та інстанси VPC

1) Щоб створити мережу mynetwork з автоматичними підмережами, виконайте таку команду:

```sh
gcloud compute networks create mynetwork --subnet-mode=auto
```

2) Щоб створити мережеву приватну мережу з власними підмережами, виконайте таку команду:

```sh
gcloud compute networks create privatenet --subnet-mode=custom
```

3) Щоб створити спеціальну підмережу в мережі privatenet, виконайте таку команду:

```sh
gcloud compute networks subnets create privatesubnet \
--network=privatenet --region=us-central1 \
--range=10.0.0.0/24 --enable-private-ip-google-access
```

4) Щоб створити кілька інстансів для тестування в усіх мережах, виконайте ці команди:

```sh
gcloud compute instances create default-us-vm \
--machine-type e2-micro \
--zone=us-central1-a --network=default
```

```sh
gcloud compute instances create mynet-us-vm \
--machine-type e2-micro \
--zone=us-central1-a --network=mynetwork
```

```sh
gcloud compute instances create mynet-eu-vm \
--machine-type e2-micro \
--zone=europe-west1-b --network=mynetwork
```

```sh
gcloud compute instances create privatenet-bastion \
--machine-type e2-micro \
--zone=us-central1-c --subnet=privatesubnet --can-ip-forward
```

```sh
gcloud compute instances create privatenet-us-vm \
--machine-type e2-micro \
--zone=us-central1-f --subnet=privatesubnet
```

## Створення настроюваних правил вхідного брандмауера (ingress firewall)

1) Щоб отримати зовнішню IP-адресу екземпляра Cloud Shell, виконайте таку команду:

```sh
ip=$(curl -s https://api.ipify.org)
echo "My External IP address is: $ip"
```

2) Щоб додати правило брандмауера, яке дозволяє трафік через порт 22 (SSH) з IP-адреси Cloud Shell, виконайте таку команду:

```sh
gcloud compute firewall-rules create \
mynetwork-ingress-allow-ssh-from-cs \
--network mynetwork --action ALLOW --direction INGRESS \
--rules tcp:22 --source-ranges $ip --target-tags=lab-ssh
```

Це правило брандмауера також має цільовий тег lab-ssh , що означає, що воно застосовується лише до інстансів, позначених тегом lab-ssh.

3) Щоб додати мережевий тег lab-ssh до екземплярів mynet-eu-vm і mynet-us-vm , виконайте такі команди в Cloud Shell:

```sh
gcloud compute instances add-tags mynet-eu-vm \
    --zone europe-west1-b \
    --tags lab-ssh
gcloud compute instances add-tags mynet-us-vm \
    --zone us-central1-a \
    --tags lab-ssh
```

4) Щоб отримати доступ до інстансів mynet-eu-vm та mynet-us-vm через ssh , виконайте такі команди в Cloud Shell:

```sh
gcloud compute ssh qwiklabs@mynet-eu-vm --zone europe-west1-b
```

```sh
 gcloud compute ssh qwiklabs@mynet-us-vm --zone us-central1-a
```

5) Щоб додати правило брандмауера, яке дозволяє ВСІМ інстансам mynetwork VPC перевіряти один одного, виконайте таку команду:

```sh
gcloud compute firewall-rules create \
mynetwork-ingress-allow-icmp-internal --network \
mynetwork --action ALLOW --direction INGRESS --rules icmp \
--source-ranges 10.128.0.0/9
```

## Зміна пріоритету у правил

1) У Cloud Shell створіть правило входу брандмауера, щоб заборонити трафік ICMP з будь-якої IP-адреси з пріоритетом 500:

```sh
gcloud compute firewall-rules create \
mynetwork-ingress-deny-icmp-all --network \
mynetwork --action DENY --direction INGRESS --rules icmp \
--priority 500
```

2) У Cloud Shell змініть щойно створене правило брандмауера та змініть пріоритет на 2000:

```sh
gcloud compute firewall-rules update \
mynetwork-ingress-deny-icmp-all \
--priority 2000
```

## Налаштувати правила вихідного брандмауера (egress firewall)

1) У Cloud Shell перелічіть усі поточні правила брандмауера для окремої мережі mynetwork:

```sh
gcloud compute firewall-rules list \
--filter="network:mynetwork"
```

2) Створіть вихідне правило брандмауера, щоб блокувати трафік ICMP з будь-якої IP-адреси з пріоритетом 10000:

```sh
gcloud compute firewall-rules create \
mynetwork-egress-deny-icmp-all --network \
mynetwork --action DENY --direction EGRESS --rules icmp \
--priority 10000
```
