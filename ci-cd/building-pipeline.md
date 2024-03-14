# Побудова a DevOps Pipeline

## Створіть Git-репозиторій

Спочатку ви створите Git-репозиторій за допомогою сервісу Cloud Source Repositories у Google Cloud. Цей Git-репозиторій буде використовуватися для зберігання вашого вихідного коду. Згодом ви створите тригер збірки, який запустить конвеєр безперервної інтеграції, коли до нього буде додано код.

1) У Хмарній консолі в меню Навігація виберіть пункт Сховища джерел. Відкриється нова вкладка.
Натисніть Додати сховище.
Виберіть Створити новий сховище і натисніть Продовжити.
Назвіть сховище devops-repo.
Виберіть поточний ідентифікатор проекту зі списку.
Натисніть Створити.
Поверніться до Хмарної консолі і натисніть Активувати хмарну оболонку ().
Якщо з'явиться відповідний запит, натисніть Продовжити.

2) Введіть у Cloud Shell наступну команду для створення теки з назвою gcp-course:

```sh
mkdir gcp-course
cd gcp-course
```

3) Тепер клонуйте порожнє сховище, яке ви щойно створили:

```sh
gcloud source repos clone devops-repo
cd devops-repo
```

## Створіть простий додаток на Python

Вам потрібен деякий вихідний код для управління. Отже, ви створите простий веб-додаток Python Flask. Додаток буде лише трохи кращим за "hello world", але його буде достатньо, щоб протестувати конвеєр, який ви побудуєте.

1) Створюємо `main.py`:

```python
from flask import Flask, render_template, request

app = Flask(__name__)

@app.route("/")
def main():
    model = {"title": "Hello DevOps Fans."}
    return render_template('index.html', model=model)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080, debug=True, threaded=True)
```

2) Також створимо нову директорію `templates` і декілька файлів html в ній:

```layout.html
<!doctype html>
<html lang="en">
<head>
    <title>{{model.title}}</title>
    <!-- Bootstrap CSS -->
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css">

</head>
<body>
    <div class="container">

        {% block content %}{% endblock %}

        <footer></footer>
    </div>
</body>
</html>
```

```index.html
{% extends "layout.html" %}
{% block content %}
<div class="jumbotron">
    <div class="container">
        <h1>{{model.title}}</h1>
    </div>
</div>
{% endblock %}
```

3) У папці devops-repo (не в папці templates) створіть новий файл і додайте до нього наступне та збережіть його під назвою requirements.txt

```requirements.txt
Flask>=2.0.3
```

4) У вас вже є деякі файли, тож збережіть їх до сховища. Спочатку вам потрібно додати всі створені вами файли до вашого локального Git-репозиторію. У Cloud Shell введіть наступний код:

```sh
cd ~/gcp-course/devops-repo
git add --all
```

```sh
git commit -a -m "Initial Commit"
```

```sh
git push origin master
```

## Підготуємо збірку Docker

Першим кроком до використання Docker є створення файлу з назвою Dockerfile. Цей файл визначає, як будується контейнер Docker. Ви зробите це зараз.

1) Вибравши теку devops-repo, у меню Файл виберіть пункт Створити файл і назвіть новий файл Dockerfile.

```docker
FROM python:3.9
WORKDIR /app
COPY . .
RUN pip install gunicorn
RUN pip install -r requirements.txt
ENV PORT=80
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 main:app
```

## Керування образами Docker за допомогою хмарної збірки та реєстру артефактів

Керування образами Docker за допомогою хмарної збірки та реєстру артефактів

1) Введіть наступну команду, щоб створити сховище реєстру артефактів з назвою devops-repo:

```sh
gcloud artifacts repositories create devops-repo \
    --repository-format=docker \
    --location=us-east1
```

2) Щоб налаштувати Docker на автентифікацію у сховищі Artifact Registry Docker, введіть наступну команду:

```sh
gcloud auth configure-docker us-east1-docker.pkg.dev
```

3) Щоб використати Cloud Build для створення образу і збереження його в реєстрі артефактів, введіть наступну команду:

```sh
gcloud builds submit --tag us-east1-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-repo/devops-image:v0.1 .
```

4) Перейдіть до сервісу Compute Engine. Натисніть кнопку Створити екземпляр, щоб створити віртуальну машину. На сторінці Створити екземпляр вкажіть наступне, а решту параметрів залиште за замовчуванням:

```
Container	Click DEPLOY CONTAINER
Container image	'us-east1-docker.pkg.dev/insert-your-project-id-here/devops-repo/devops-image:v0.1` (change the project ID where indicated) and click SELECT
Firewall	Allow HTTP traffic
```

5) Натисніть "Створити". Після запуску віртуальної машини натисніть зовнішню IP-адресу віртуальної машини. Відкриється вкладка браузера, на якій буде показано сторінку Hello DevOps Fans.

6) Тепер ви збережете ваші зміни до вашого Git-репозиторію. У Cloud Shell введіть наступне, щоб переконатися, що ви знаходитесь у правильній папці, і додайте ваш новий Docker-файл до Git'у:

```sh
cd ~/gcp-course/devops-repo
git add --all
```

```sh
git commit -am "Added Docker Support"
```

```sh
git push origin master
```








