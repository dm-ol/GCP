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

Клонуємо git-репозиторій, що містить веб-додаток, і розгортаєм зображення контейнерів додатку в Artifact Registry.

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

## Налаштуйте цілі розгортання

Буде створено три об'єкти конвеєра (pipeline) доставки - по одному для кожного з кластерів GKE.

1) Три кластери GKE мають бути запущені, але корисно це перевірити.

```sh
gcloud container clusters list --format="csv(name,status)"
```

Усі три кластери мають бути у стані RUNNING, як показано у виведенні нижче. Якщо вони ще не позначені як запущені, повторіть наведену вище команду, доки їхній стан не зміниться на RUNNING.

2) Створіть контекст для кожного кластера
Скористайтеся наведеними нижче командами, щоб отримати облікові дані для кожного кластера і створити простий у використанні контекст kubectl для подальшого посилання на кластери:

```sh
CONTEXTS=("test" "staging" "prod")
for CONTEXT in ${CONTEXTS[@]}
do
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done

```

3) Створення простору імен у кожному кластері
Скористайтеся наведеними нижче командами, щоб створити простір імен Kubernetes (веб-додаток) у кожному з трьох кластерів:

```sh
for CONTEXT in ${CONTEXTS[@]}
do
    kubectl --context ${CONTEXT} apply -f kubernetes-config/web-app-namespace.yaml
done
```

4) Створіть цілі конвеєра (pipeline) доставки
Надайте визначення для кожної з цілей:

```sh
for CONTEXT in ${CONTEXTS[@]}
do
    envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
    gcloud beta deploy apply --file clouddeploy-config/target-$CONTEXT.yaml
done
```

5) Відобразити деталі для тестової цілі:

```sh
cat clouddeploy-config/target-test.yaml
```

6) Відобразити деталі для прод-таргету:

```sh
cat clouddeploy-config/target-prod.yaml
```

7) Переконайтеся, що три цілі (test, staging, prod) створено:

```sh
gcloud beta deploy targets list
```

## Створіть реліз

Випуск Google Cloud Deploy - це конкретна версія одного або декількох зображень контейнера, пов'язана з певним конвеєром доставки. Після створення релізу його можна просувати через кілька цілей (послідовність просування). Крім того, при створенні релізу ваш додаток рендерить за допомогою скафолду і зберігає результат як посилання на точку в часі, яке використовується протягом усього терміну дії цього релізу.
Оскільки це перший реліз вашого додатку, ви назвете його web-app-001.

1) Запустіть наступну команду, щоб створити реліз:

```sh
gcloud beta deploy releases create web-app-001 \
--delivery-pipeline web-app \
--build-artifacts web/artifacts.json \
--source web/
```

Параметр --build-artifacts посилається на файл artifacts.json, створений skaffold раніше. Параметр --source посилається на директорію з вихідним кодом програми, де знаходиться skaffold.yaml.
Після створення релізу він також буде автоматично розгорнутий до першої цілі у конвеєрі (якщо не потрібне схвалення, яке буде розглянуто у наступному кроці цієї лабораторної роботи).

2) Щоб переконатися, що на тестовому об'єкті розгорнуто вашу програму, виконайте наступну команду:

```sh
gcloud beta deploy rollouts list \
--delivery-pipeline web-app \
--release web-app-001
```

3) Переконайтеся, що ваш додаток було розгорнуто на тестовому кластері GKE, виконавши наступні команди:

```sh
kubectx test
kubectl get all -n web-app
```

## Просування заявки на стадіювання

Будемо просувати додаток з тестової версії до цільової.

1) Просувайте заявку до staging:

```sh
gcloud beta deploy releases promote \
--delivery-pipeline web-app \
--release web-app-001
```

Натисніть ENTER, щоб прийняти значення за замовчуванням (Y = так).

2) Щоб переконатися, що на staging цілі розгорнуто вашу програму, виконайте наступну команду:

```sh
gcloud beta deploy rollouts list \
--delivery-pipeline web-app \
--release web-app-001
```

## Просувайте заявку на прод

1) Просувайте заявку до prod:

```sh
gcloud beta deploy releases promote \
--delivery-pipeline web-app \
--release web-app-001
```

Натисніть ENTER, щоб прийняти значення за замовчуванням (Y = так).

2) Щоб переконатися, що на prod цілі розгорнуто вашу програму, виконайте наступну команду:

```sh
gcloud beta deploy rollouts list \
--delivery-pipeline web-app \
--release web-app-001
```

3) Схвалити розгортання з урахуванням наступного:

```sh
gcloud beta deploy rollouts approve web-app-001-to-prod-0001 \
--delivery-pipeline web-app \
--release web-app-001
```

4) Щоб переконатися, що на цільовому об'єкті розгорнуто вашу програму, виконайте наступну команду:

```sh
gcloud beta deploy rollouts list \
--delivery-pipeline web-app \
--release web-app-001
```

5) Переконайтеся, що ваш додаток було розгорнуто на prod кластері GKE, виконавши наступні команди:

```sh
kubectx prod
kubectl get all -n web-app
```











