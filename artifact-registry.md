# Створення Docker-репозиторія у Artifact реєстрі

## Реєстр артефактів підтримує керування зображеннями контейнерів та мовними пакунками. Різні типи артефактів вимагають різних специфікацій. Наприклад, запити до залежностей Maven відрізняються від запитів до залежностей Node.
Щоб підтримувати різні специфікації API, Artifact Registry повинен знати, у якому форматі ви хочете отримати відповіді від API. Для цього вам потрібно створити сховище і вказати прапорець --repository-format, який вказує на тип бажаного сховища.

1) У Cloud Shell виконайте наступну команду, щоб створити сховище для образів Docker:

```sh
gcloud artifacts repositories create container-dev-repo --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for Container Dev Workshop"
```

2) Налаштуйте автентифікацію Docker до реєстру артефактів. При підключенні до Artifact Registry для надання доступу потрібні облікові дані.
Замість того, щоб створювати окремі облікові дані, Docker можна налаштувати так, щоб він без проблем використовував ваші облікові дані gcloud.
З Cloud Shell виконайте наступну команду, щоб налаштувати Docker на використання Google Cloud CLI для автентифікації запитів до реєстру артефактів у регіоні:

```sh
gcloud auth configure-docker us-west1-docker.pkg.dev
```

3) Приклад створення образ контейнера:

```sh
docker build -t us-west1-docker.pkg.dev/qwiklabs-gcp-04-bbab34ac6ccc/container-dev-repo/java-hello-world:tag1 .
```

4) Перенесіть зображення контейнера до реєстру артефактів:

```sh
docker push us-west1-docker.pkg.dev/qwiklabs-gcp-04-bbab34ac6ccc/container-dev-repo/java-hello-world:tag1
```

5) Створення репозиторію пакетів Java:

```sh
gcloud artifacts repositories create container-dev-java-repo \
    --repository-format=maven \
    --location=us-central1 \
    --description="Java package repository for Container Dev Workshop"
```

6) Скористайтеся наступною командою, щоб оновити загальновідоме місце для облікових даних за замовчуванням програми (ADC) обліковими даними вашого облікового запису користувача, щоб помічник з облікових даних реєстру артефактів міг автентифікуватися за ними під час з'єднання зі сховищами:

```sh
gcloud auth login --update-adc
```
Якщо з'явиться запит на автентифікацію:

Виберіть Y.
Вставте код у вікно браузера.
Виберіть Google Sign In і увійдіть, використовуючи облікові дані в лабораторії.
Скопіюйте код автентифікації з браузера назад в консоль, щоб завершити автентифікацію.

7) Налаштування Maven для реєстру артефактів

```sh
gcloud artifacts print-settings mvn \
    --repository=container-dev-java-repo \
    --location=us-central1
```
