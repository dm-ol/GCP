# Set up variables

```sh
export PROJECT_ID=$(gcloud config get-value project)
```
```sh
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
```
```sh
export REGION=
```
```sh
gcloud config set compute/region $REGION
```
