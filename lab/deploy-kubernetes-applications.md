# Deploy Kubernetes Applications on Google Cloud: Challenge Lab

## Task 1:

gcloud auth list
gsutil cat gs://cloud-training/gsp318/marking/setup_marking_v2.sh | bash
gcloud source repos clone valkyrie-app
cd valkyrie-app
cat > Dockerfile <<EOF
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOF
docker build -t valkyrie-prod:v0.0.3 .
cd ..
cd marking
./step1_v2.sh




## Task 2:-
cd ..
cd valkyrie-app
docker run -p 8080:8080 valkyrie-prod:v0.0.3 &
cd ..
cd marking
./step2_v2.sh
bash ~/marking/step2_v2.sh


## Task 3:-

cd ..
cd valkyrie-app

gcloud artifacts repositories create valkyrie-repo \
    --repository-format=docker \
    --location=us-east1 \
    --async 

gcloud auth configure-docker us-east1-docker.pkg.dev

docker images

docker tag Image_ID us-east1-docker.pkg.dev/qwiklabs-gcp-01-6a575bdf7613/valkyrie-repo/valkyrie-prod:v0.0.3

docker push us-east1-docker.pkg.dev/qwiklabs-gcp-01-6a575bdf7613/valkyrie-repo/valkyrie-prod:v0.0.3



## Task 4:-

sed -i s#IMAGE_HERE#us-east1-docker.pkg.dev/qwiklabs-gcp-01-6a575bdf7613/valkyrie-repo/valkyrie-prod:v0.0.3#g k8s/deployment.yaml

gcloud container clusters get-credentials valkyrie-dev --zone us-east1-c
kubectl create -f k8s/deployment.yaml
kubectl create -f k8s/service.yaml

