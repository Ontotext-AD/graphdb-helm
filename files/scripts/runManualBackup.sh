#!/usr/bin/env bash

kubectl patch cronjobs backup-manual -p '{"spec" : {"suspend" : false }}'
sleep 10
kubectl patch cronjobs backup-manual -p '{"spec" : {"suspend" : true }}'

