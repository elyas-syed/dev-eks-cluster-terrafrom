#!/bin/bash

# Apply the storage class first
kubectl apply -f storage-class.yaml

# Apply the rest of your manifests
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f persistent-volume.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml

echo "Sample app deployed successfully!"
echo "Check status with: kubectl get pods,pvc,storageclass"