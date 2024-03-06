# Безперервна доставка (CD) з Google Cloud Deploy

### Google Cloud Deploy - це керований сервіс, який автоматизує доставку ваших додатків до низки цільових середовищ у визначеній послідовності просування.
### Коли ви хочете розгорнути оновлену програму, ви створюєте реліз, життєвим циклом якого керує конвеєр доставки.

## Встановимо змінні

Оголосіть змінні оточення, які будуть використовуватися різними командами:

```sh
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-west1
gcloud config set compute/region $REGION
```

## Створіть три кластери GKE

У цьому завданні ви створите три кластери GKE, які стануть цілями для конвеєра доставки.
Буде створено три кластери GKE, які позначають три цілі для конвеєра доставки:
- test
- staging
- prod

1) Увімкніть Google Kubernetes Engine API:

```sh
gcloud services enable \
container.googleapis.com \
clouddeploy.googleapis.com
```

2) Створіть три кластери GKE:

```sh
gcloud container clusters create test --node-locations=us-west1-c --num-nodes=1  --async
gcloud container clusters create staging --node-locations=us-west1-c --num-nodes=1  --async
gcloud container clusters create prod --node-locations=us-west1-c --num-nodes=1  --async
```

3) Перевірте стан трьох кластерів:

```sh
gcloud container clusters list --format="csv(name,status)"
```

## Підготуйте зображення контейнера веб-додатку

1) Увімкніть API реєстру артефактів:

```sh
gcloud services enable artifactregistry.googleapis.com
```

2) Створіть репозиторій веб-додатку для зберігання зображень контейнерів:

```sh
gcloud artifacts repositories create web-app \
--description="Image registry for tutorial web app" \
--repository-format=docker \
--location=$REGION
```

## Створіть і розгорніть образи контейнерів до реєстру артефактів

### Клонуємо git-репозиторій, що містить веб-додаток, і розгортаєм зображення контейнерів додатку в Artifact Registry.

1) Скопіюйте сховище з тестом до вашого домашнього каталогу:

```sh
cd ~/
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
cd cloud-deploy-tutorials
git checkout c3cae80 --quiet
cd tutorials/base
```

2) Створіть конфігурацію skaffold.yaml:

```sh
envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml
cat web/skaffold.yaml
```

У веб-каталозі тепер міститься файл конфігурації skaffold.yaml, який містить інструкції для Skaffold щодо створення образу контейнера для вашої програми. Ця конфігурація описує наступні елементи.

Розділ збірки конфігурує:

Два образи контейнера, які будуть побудовані (артефакти)
Проект Google Cloud Build, за допомогою якого буде зібрано образи
У розділі deploy налаштовуються маніфести Kubernetes, необхідні для розгортання робочого навантаження на кластер.

Конфігурація portForward використовується для визначення служби Kubernetes для розгортання.

3) Увімкніть API хмарної збірки:

```sh
gcloud services enable cloudbuild.googleapis.com
```

4) Запустіть команду skaffold, щоб зібрати додаток і розгорнути образ контейнера до раніше створеного сховища реєстру артефактів:

```sh
cd web
skaffold build --interactive=false \
--default-repo $REGION-docker.pkg.dev/$PROJECT_ID/web-app \
--file-output artifacts.json
cd ..
```

5) Після завершення збірки скафолду перевірте наявність зображень контейнерів у реєстрі артефактів:

```sh
gcloud artifacts docker images list \
$REGION-docker.pkg.dev/$PROJECT_ID/web-app \
--include-tags \
--format yaml
```

За замовчуванням Skaffold встановлює тег для зображення на відповідний тег git'а, якщо він доступний. Подібну інформацію можна знайти у файлі artifacts.json, створеному командою skaffold.

Skaffold створює файл web/artifacts.json з деталями розгорнутих зображень:

```sh
cat web/artifacts.json | jq
```

## Створіть конвеєр (pipeline) доставки

1) Увімкніть Google Cloud Deploy API:

```sh
gcloud services enable clouddeploy.googleapis.com
```

2) Створіть ресурс конвеєра доставки за допомогою файлу delivery-pipeline.yaml:

```sh
gcloud config set deploy/region $REGION
cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml
```

3) Переконайтеся, що конвеєр доставки створено:

```sh
gcloud beta deploy delivery-pipelines describe web-app
```

















