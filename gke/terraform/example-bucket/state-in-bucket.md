# Створення Remote Backend

## Додати локальний бекенд

1) Створіть у main.tf код bucket:

```json
resource "google_storage_bucket" "test-bucket-for-state" {
  name        = "qwiklabs-gcp-04-492aa8407ae2"
  location    = "US" # Replace with EU for Europe region
  uniform_bucket_level_access = true
  force_destroy = true
}
```

2) Додайте локальний бекенд до свого main.tfфайлу:

```json
terraform {
  backend "local" {
    path = "terraform/state/terraform.tfstate"
  }
}
```

3) ініціалізуйте Terraform за допомогою такої команди:

```sh
terraform init
```

4) Застосуйте зміни. Введіть yes у ​​запиті для підтвердження.

```sh
terraform apply
```

## Додайте бекенд Cloud Storage

1) Щоб змінити наявну локальну конфігурацію серверної частини, замініть код для локальної серверної частини такою конфігурацією у main.tfфайлі.

```json
terraform {
  backend "gcs" {
    bucket  = "qwiklabs-gcp-04-492aa8407ae2"
    prefix  = "terraform/state"
  }
}
```

2) Знову ініціалізуйте серверну частину. Введіть yes у ​​запиті для підтвердження.

```sh
terraform init -migrate-state
```

3) При потребі поверніться до Cloud Shell і скористайтеся такою командою, щоб оновити файл стану:

```sh
terraform refresh
```