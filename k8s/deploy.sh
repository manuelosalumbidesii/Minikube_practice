#!/bin/bash

echo "Automating the deployment of kubernetes minbikube"

kubectl apply -f backend-deployement.yaml
kubectl apply -f frontend-deployement.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-service.yaml
kubectl apply -f ingress.yaml   

echo "Deployment completed successfully!"
