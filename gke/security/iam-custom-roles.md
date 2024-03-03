# Спеціальні ролі IAM

## Переглянути доступні дозволи для ресурсу

```sh
gcloud iam list-testable-permissions //cloudresourcemanager.googleapis.com/projects/$DEVSHELL_PROJECT_ID
```

## Створіть власну роль за допомогою файлу YAML

1) Створіть файл YAML, який містить визначення вашої спеціальної ролі. Файл повинен бути структурований таким чином:

```yaml
title: [ROLE_TITLE]
description: [ROLE_DESCRIPTION]
stage: [LAUNCH_STAGE]
includedPermissions:
- [PERMISSION_1]
- [PERMISSION_2]
```

[ROLE_TITLE]це зрозуміла назва для ролі, наприклад Role Viewer .
[ROLE_DESCRIPTION]– це короткий опис ролі, наприклад опис моєї спеціальної ролі .
[LAUNCH_STAGE]вказує на стадію ролі в життєвому циклі запуску, наприклад АЛЬФА, БЕТА або GA.
includedPermissionsвказує список одного або кількох дозволів, які слід включити до спеціальної ролі, наприклад iam.roles.get .

2) Створіть файл визначення ролі role-definition.yaml:

```yaml
title: "Role Editor"
description: "Edit access for App Versions"
stage: "ALPHA"
includedPermissions:
- appengine.versions.create
- appengine.versions.delete
```

3) Виконайте таку gcloudкоманду:

```sh
gcloud iam roles create editor --project $DEVSHELL_PROJECT_ID \
--file role-definition.yaml
```

## Створіть власну роль за допомогою прапорців

Виконайте таку gcloudкоманду, щоб створити нову роль за допомогою прапорців:

```sh
gcloud iam roles create viewer --project $DEVSHELL_PROJECT_ID \
--title "Role Viewer" --description "Custom role description." \
--permissions compute.instances.get,compute.instances.list --stage ALPHA
```

## Перелічіть настроювані ролі

Виконайте таку gcloudкоманду, щоб створити список настроюваних ролей, указавши настроювані ролі на рівні проекту або на рівні організації:

```sh
gcloud iam roles list --project $DEVSHELL_PROJECT_ID
```

## Оновіть настроювану роль за допомогою файлу YAML

1) Отримайте поточне визначення для ролі, виконавши наведену нижче gcloudкоманду, замінивши її [ROLE_ID] на editor .

```sh
gcloud iam roles describe editor --project $DEVSHELL_PROJECT_ID
```

2) Створіть new-role-definition.yaml файл

```yaml
description: Edit access for App Versions
etag: BwVxIAbRq_I=
includedPermissions:
- appengine.versions.create
- appengine.versions.delete
- storage.buckets.get
- storage.buckets.list
name: projects/Project ID/roles/editor
stage: ALPHA
title: Role Editor
```

3) Тепер ви скористаєтеся updateкомандою для оновлення ролі. Виконайте наступну gcloudкоманду, замінивши [ROLE_ID]на editor :

```sh
gcloud iam roles update [ROLE_ID] --project $DEVSHELL_PROJECT_ID \
--file new-role-definition.yaml
```

## Оновіть настроювану роль за допомогою прапорців

Використовуйте такі позначки, щоб додати або видалити дозволи:

--add-permissions: додає до ролі один або кілька дозволів, розділених комами.
--remove-permissions: вилучає з ролі один або кілька дозволів, розділених комами.

Виконайте таку gcloudкоманду, щоб додати дозволи до ролі переглядача за допомогою прапорців:

```sh
gcloud iam roles update viewer --project $DEVSHELL_PROJECT_ID \
--add-permissions storage.buckets.get,storage.buckets.list
```

## Відключити настроювану роль

Виконайте таку gcloudкоманду, щоб вимкнути роль переглядача :

```sh
gcloud iam roles update viewer --project $DEVSHELL_PROJECT_ID \
--stage DISABLED
```


## Видалити настроювану роль

Використовуйте gcloud iam roles deleteкоманду, щоб видалити настроювану роль. Після видалення роль стає неактивною та не може використовуватися для створення нових прив’язок політики IAM:

```sh
gcloud iam roles delete viewer --project $DEVSHELL_PROJECT_ID
```

## Відновити настроювану роль

Протягом 7 днів ви можете відновити роль. Видалені ролі перебувають у стані ВИМКНЕНО . Щоб знову зробити його доступним, оновіть --stageпрапор:

```sh
gcloud iam roles undelete viewer --project $DEVSHELL_PROJECT_ID
```

