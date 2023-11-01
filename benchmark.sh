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
  podman run -d --network host --name "$container_name" "$image_name"
  wait_for_container "$container_name"
  
  # Run the benchmark and capture the output
  time -o "$output_file" podman exec "$container_name" sh -c "$command_to_run"
}

# Vector + VictoriaLogs
run_benchmark "vector_vl" "docker.io/timberio/vector:latest" "vector_vl_benchmark.txt" "vector -f test.log -o http://victorialogs_vl:8428/insert"

run_benchmark "victorialogs_vl" "docker.io/victorialogs/victorialogs:latest" "victorialogs_vl_benchmark.txt" "curl http://localhost:8428/select/logsql/query -d 'query=error'"

# Filebeat + VictoriaLogs
run_benchmark "filebeat_vl" "docker.io/library/filebeat:latest" "filebeat_vl_benchmark.txt" "filebeat -e -strict.perms=false -c /etc/filebeat/filebeat.yml"

# Vector + ClickHouse
run_benchmark "vector_ch" "docker.io/timberio/vector:latest" "vector_ch_benchmark.txt" "vector -f test.log -o http://clickhouse_ch:8123/insert"

run_benchmark "clickhouse_ch" "docker.io/yandex/clickhouse-server:latest" "clickhouse_ch_benchmark.txt" "clickhouse-client --host clickhouse_ch --query 'SELECT COUNT(*) FROM example_database.example_table'"

# Clean up containers
podman stop vector_vl victorialogs_vl filebeat_vl vector_ch clickhouse_ch
podman rm vector_vl victorialogs_vl filebeat_vl vector_ch clickhouse_ch
