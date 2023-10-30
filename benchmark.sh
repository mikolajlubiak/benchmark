#!/bin/bash

# Function to check if a Podman container is running
container_is_running() {
  local container_name="$1"
  podman ps -q -f "name=${container_name}" | grep -q .
}

# Function to wait for a container to start
wait_for_container() {
  local container_name="$1"
  while ! container_is_running "$container_name"; do
    sleep 1
  done
}

# Function to run the benchmark
run_benchmark() {
  local container_name="$1"
  local image_name="$2"
  local output_file="$3"
  local command_to_run="$4"
  
  # Start the container
  podman run -d --name "$container_name" "$image_name"
  wait_for_container "$container_name"
  
  # Run the benchmark and capture the output
  time -o "$output_file" podman exec "$container_name" sh -c "$command_to_run"
}

# Spin up containers for log collectors and databases
run_benchmark "filebeat" "docker.io/library/filebeat:latest" "filebeat_benchmark.txt" "your_filebeat_command"
run_benchmark "vector" "docker.io/timberio/vector:latest" "vector_benchmark.txt" "your_vector_command"
run_benchmark "clickhouse" "docker.io/yandex/clickhouse-server:latest" "clickhouse_benchmark.txt" "your_clickhouse_command"
run_benchmark "victorialogs" "docker.io/victorialogs/victorialogs:latest" "victorialogs_benchmark.txt" "your_victorialogs_command"

# Clean up containers
podman stop filebeat vector clickhouse victorialogs
podman rm filebeat vector clickhouse victorialogs
