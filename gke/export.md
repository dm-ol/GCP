## Export ID проєкту:

```sh
export PROJECT_ID=$(gcloud config get-value project)
```

## Export номеру проєкту:

```sh
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
```
