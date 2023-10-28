#!/bin/bash

LOG_FILE="logfile.log"

cat <<EOF > vector-config.toml
[sources.my_source]
  type = "file"
  include = ["/var/log/vector/*.log"]

[sinks.my_sink]
  type = "clickhouse"
  inputs = ["my_source"]
  host = "clickhouse-host"
  port = 8123
  database = "my_logs"
  table = "logs"
  username = "your_username"
  password = "your_password"
  batch = 1000
EOF

mkdir -p /var/log/vector
cp "$LOG_FILE" /var/log/vector/

podman run -d --name clickhouse-container --ulimit nofile=262144:262144 yandex/clickhouse-server

sleep 10

podman run -d --name vector-container -v vector-config.toml:/etc/vector/vector.toml -v /var/log/vector:/var/log/vector timberio/vector:latest vector --config /etc/vector/vector.toml

sleep 10

echo "Benchmark zbierania logów z Vector do ClickHouse"
time vector

sleep 10

echo "Benchmark przetwarzania logów w ClickHouse"
time clickhouse-client --query "SELECT COUNT(*) FROM logs"

podman stop vector-container
podman stop clickhouse-container
podman rm vector-container
podman rm clickhouse-container

