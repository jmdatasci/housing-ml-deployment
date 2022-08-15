#!/bin/sh

#SUBSCRIPTION_ID=6baae99a-4d64-4071-bfac-c363e71984c3
#az account set --subscription="${SUBSCRIPTION_ID}"

#minikube start --kubernetes-version=v1.22.6

az login --tenant berkeleydatasciw255.onmicrosoft.com
az account set --subscription=6baae99a-4d64-4071-bfac-c363e71984c3
az aks get-credentials --name w255-aks --resource-group w255 --overwrite-existing
kubectl config use-context w255-aks
kubelogin convert-kubeconfig

az acr login --name w255mids
az aks get-credentials --name w255-aks --resource-group w255 --overwrite-existing

IMAGE_PREFIX=jordanmeyer
#IMAGE_PREFIX=$(az account list --all | jq '.[].user.name' | grep -i berkeley.edu | awk -F@ '{print $1}' | tr -d '"' | uniq)
#FQDN = Fully-Qualiifed Domain Name
IMAGE_NAME=lab4
ACR_DOMAIN=w255mids.azurecr.io
TAG=41ffc21
IMAGE_FQDN="${ACR_DOMAIN}/${IMAGE_PREFIX}/${IMAGE_NAME}:${TAG}"

cd lab4
docker build --platform linux/amd64 --no-cache -t ${IMAGE_NAME}:${TAG} .

docker tag "${IMAGE_NAME}" ${IMAGE_FQDN}
docker push "${IMAGE_FQDN}"
docker pull "${IMAGE_FQDN}"

#eval $(minikube -p minikube docker-env)
#docker build -t lab4 .
#kubectl kustomize .k8s/overlays/dev
#kubectl apply -k .k8s/overlays/dev
#minikube tunnel
#minikube ip
#kubectl port-forward service/lab4 8000:8000 &

NAMESPACE=jordanmeyer
kubectl --namespace externaldns logs -l "app.kubernetes.io/name=external-dns,app.kubernetes.io/instance=external-dns"
kubectl --namespace istio-ingress get certificates ${NAMESPACE}-cert
kubectl --namespace istio-ingress get certificaterequests
kubectl --namespace istio-ingress get gateways ${NAMESPACE}-gateway

kubectl config set-context --current --namespace=jordanmeyer

kubectl kustomize .k8s/bases
kubectl apply -k .k8s/bases
kubectl kustomize .k8s/overlays/dev
kubectl apply -k .k8s/overlays/dev


kubectl config use-context w255-aks
kubelogin convert-kubeconfig
kubectl kustomize .k8s/overlays/prod
kubectl apply -k .k8s/overlays/prod
kubectl config set-context --current --namespace=jordanmeyer



cd ..
NAMESPACE=jordanmeyer
curl -X 'POST' 'https://jordanmeyer.mids-w255.com/predict' -L -H 'Content-Type: application/json' -d '[{ "MedInc": 8.3252, "HouseAge": 42, "AveRooms": 6.98, "AveBedrms": 1.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 }]'
curl -X 'POST' 'https://jordanmeyer.mids-w255.com/predict' -L -H 'Content-Type: application/json' -d '[{ "MedInc": 8.3252, "HouseAge": 42, "AveRooms": 6.98, "AveBedrms": 1.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 },{ "MedInc": 2.3252, "HouseAge": 20, "AveRooms": 2.98, "AveBedrms": 1.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 },{ "MedInc": 3.3252, "HouseAge": 12, "AveRooms": 4.5, "AveBedrms": 3.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 },{ "MedInc": 4.3252, "HouseAge": 42, "AveRooms": 6.98, "AveBedrms": 2.02, "Population": 123, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 }]'

curl -X 'POST' 'https://jordanmeyer.mids-w255.com/predict' -L -H 'Content-Type: application/json' -d '{"user_in":[{ "MedInc": 8.3252, "HouseAge": 42, "AveRooms": 6.98, "AveBedrms": 1.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 },{ "MedInc": 2.3252, "HouseAge": 20, "AveRooms": 2.98, "AveBedrms": 1.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 },{ "MedInc": 3.3252, "HouseAge": 12, "AveRooms": 4.5, "AveBedrms": 3.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 },{ "MedInc": 4.3252, "HouseAge": 42, "AveRooms": 6.98, "AveBedrms": 2.02, "Population": 123, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 }]}'

curl -X 'POST' 'https://jordanmeyer.mids-w255.com/predict' -L -H 'Content-Type: application/json' -d '{'user_in':[{ "MedInc": 8.3252, "HouseAge": 42, "AveRooms": 6.98, "AveBedrms": 1.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 },{ "MedInc": 2.3252, "HouseAge": 20, "AveRooms": 2.98, "AveBedrms": 1.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 },{ "MedInc": 3.3252, "HouseAge": 12, "AveRooms": 4.5, "AveBedrms": 3.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 },{ "MedInc": 4.3252, "HouseAge": 42, "AveRooms": 6.98, "AveBedrms": 2.02, "Population": 123, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 }]}'
