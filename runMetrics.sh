#!/bin/bash
metrics_output_folder="metrics"
container_name="kcov_container"
kcov_image="custom_kcov"
kcov_metrics_folder="/tmp/cov/."

[ ! -d "$metrics_output_folder" ] && mkdir "$metrics_output_folder"
docker ps -a | grep -q "$container_name$" && docker rm "$container_name"

docker build -t $kcov_image .
docker run \
   -it \
   --name="$container_name" \
   --security-opt seccomp=unconfined \
     $kcov_image \
     --version
docker cp $container_name:$kcov_metrics_folder metrics/
