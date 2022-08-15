#!/bin/sh
echo "Building lab4 app"

#Check if there is already an existing container on port 8000, if there is then terminate it
if [ "$( docker ps -a --filter publish=8000 | wc -l)" -gt 1 ]; then
  echo "Terminating docker container"
  docker stop "$(docker ps --filter publish=8000 --quiet)"
fi

if [ ! -e  "lab4/model_pipeline.pkl" ]
then
    python /trainer/train.py
fi

# Start minikube and create namespace
minikube start --kubernetes-version=v1.22.6
alias kubectl="minikube kubectl --"

#prepare kubernetes by clearing namespace
if [ $(kubectl get ns w255) ]
then
    echo "\nCleaning up existing infrastructure"
    echo "\nDeleting Pods, Services, Deployments"
    kubectl delete --all pods,svc,deploy --namespace=jordanmeyer
    echo "\nDeleting Namespace jordanmeyer"
    kubectl delete ns jordanmeyer
    minikube stop

fi
echo "Creating new jordanmeyer namespace"

kubectl apply -f lab4/infra/namespace.yaml
kubectl config set-context --current --namespace=jordanmeyer
APP_HOST=$(minikube ip)
APP_PORT=31111

# Set context and build app
eval $(minikube docker-env)
cd ./lab4 || exit
docker build --file ./Dockerfile --tag lab4 .

# Deploy Infrastructure
kubectl apply -f infra/deployment-pythonapi.yaml && kubectl apply -f infra/service-pythonapi.yaml
kubectl apply -f infra/deployment-redis.yaml && kubectl apply -f infra/service-redis.yaml

## old lab stuff replaced with k8s
# build the container and run it
#cd ./lab4 || exit
#docker build --file ./Dockerfile --tag my-app .
#docker run --detach --publish 8000:8000 --rm my-app

echo "Starting up lab4 app on ${APP_HOST}:${APP_PORT}, one moment.."
echo "\n"
#Check if port is open before proceeding
while [ $(curl -o /dev/null -s -w "%{http_code}" -X GET "http://${APP_HOST}:${APP_PORT}/docs") != "200" ]
do
  sleep 0.25
done
sleep 2
echo "Container lab4 app is now online at ${APP_HOST}:${APP_PORT}."
echo "\n"

# send some curl commands to the container
echo "Testing a valid query \"/hello?name=jordan\": expecting 200"
curl --output /dev/null --silent --write-out "%{http_code}\n" --request GET "http://${APP_HOST}:${APP_PORT}/hello?name=jordan"
echo "\n"

sleep 1
echo "Testing a root \"/\" query: expecting 404"
curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://${APP_HOST}:${APP_PORT}/"
echo "\n"

sleep 1
echo "Testing a docs \"/docs\" query: expecting 200"
curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://${APP_HOST}:${APP_PORT}/docs"
echo "\n"

sleep 1
echo "Testing an blank but valid parameter \"/hello?me=\" query: expecting 422"
curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://${APP_HOST}:${APP_PORT}/hello?name="
echo "\n"

sleep 1
echo "Testing an invalid parameter \"/hello?me=jordan\" query: expecting 422"
curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://${APP_HOST}:${APP_PORT}/hello?me=jordan"
echo "\n"

sleep 1
echo "Testing an openapi.json \"/openapi.json\" call:  expecting 200"
curl -o /dev/null -s -w "%{http_code}\n" --request GET "http://${APP_HOST}:${APP_PORT}/openapi.json"

echo "\nTesting Prediction Endpoint"
sleep 1

echo "\nTesting a valid \"/predict\" call."
curl -X 'POST' \
  "http://${APP_HOST}:${APP_PORT}/predict" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '[{
  "MedInc": 1,
  "HouseAge": 1,
  "AveRooms": 1,
  "AveBedrms": 1,
  "Population": 1,
  "AveOccup": 1,
  "Latitude": 1,
  "Longitude": 1
}]'
echo "\n"

sleep 1
echo "\nTesting a \"/predict\" with parameters out of range: expecting 422"
curl -X 'POST' \
  "http://${APP_HOST}:${APP_PORT}/predict" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '[{
  "MedInc": -1,
  "HouseAge": -1,
  "AveRooms": -1,
  "AveBedrms": -1,
  "Population": -1,
  "AveOccup": -1,
  "Latitude": 200,
  "Longitude": 200
}]'
echo "\n"

sleep 1
echo "\nTesting a \"/predict\" call missing parameters: expecting 422"
curl -X 'POST' \
  "http://${APP_HOST}:${APP_PORT}/predict" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '[{}]'
echo "\n"


sleep 1
echo "\nTesting a \"/predict\" call expecting prediction: [4.414593298251905]"
curl -X 'POST' "http://192.168.49.2:31111/predict" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-d '[{"HouseAge":41,"MedInc":8.32,"AveRooms":6.98,"AveBedrms":1.02,"Population":322,"AveOccup":2.5,"Latitude":37.88,"Longitude":-122.21}]'
echo "\n"

sleep 1
echo "\nTesting a \"/predict\" call with a long list of inputs."
curl -X 'POST' "http://${APP_HOST}:${APP_PORT}/predict" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-d '[{"MedInc": 1,"HouseAge": 1,"AveRooms": 1,"AveBedrms": 1,"Population": 1,"AveOccup": 1,"Latitude": 1,"Longitude": 1},{"MedInc": 2,"HouseAge": 2,"AveRooms": 2,"AveBedrms": 2,"Population": 2,"AveOccup": 2,"Latitude": 90,"Longitude": 90},{"MedInc": 5,"HouseAge": 5,"AveRooms": 5,"AveBedrms": 5,"Population": 5,"AveOccup": 5,"Latitude": 90,"Longitude": 90},{"HouseAge":41,"MedInc":8.32,"AveRooms":6.98,"AveBedrms":1.02,"Population":322,"AveOccup":2.5,"Latitude":37.88,"Longitude":-122.21}]'
echo "\n"



#check if user wanted container to persist otherwise terminate.
if ! [ $# -eq 1 ] && ! [ "$1" = "persist" ]
  then
    echo "\nCleaning up"
    echo "\nDeleting Pods, Services, Deployments"
    kubectl delete --all pods,svc,deploy --namespace=w255
    echo "\nDeleting Namespace w255"
    kubectl delete ns w255
    minikube stop

else
    echo "\nKeeping cluster open at ${APP_HOST}:${APP_PORT}"
fi

##verify caches
#kubectl logs -f -n ${NAMESPACE} -l app=${APP_NAME}
#kubectl logs -f $(kubectl get pods -A | grep lab4-854cbf4bbf-t56p7 | tail -1 | awk '{print $2}') --namespace=w255
#kubectl logs -f $(kubectl get pods -A | grep my-app-service | tail -1 | awk '{print $2}') --namespace=w255
#kubectl logs -f $(kubectl get pods -A | grep redis | tail -1 | awk '{print $2}') --namespace=w255
#kubectl logs -f $(kubectl get pods -A | grep redis-service | tail -1 | awk '{print $2}') --namespace=w255