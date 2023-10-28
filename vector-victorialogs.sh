#!/bin/bash

LOG_FILE="logfile.log"

cat <<EOF > vector-config.toml
[sources.my_source]
  type = "file"
  include = ["/var/log/vector/*.log"]

[sinks.my_sink]
  type = "http"
  inputs = ["my_source"]
  target = "http://victorialogs-host:8420/api/v1/write"
EOF

mkdir -p /var/log/vector
cp "$LOG_FILE" /var/log/vector/

podman run -d --name victorialogs-container -p 8420:8420 victorialogs/victorialogs

sleep 10

podman run -d --name vector-container -v vector-config.toml:/etc/vector/vector.toml -v /var/log/vector:/var/log/vector timberio/vector:latest vector --config /etc/vector/vector.toml

sleep 10

echo "Benchmark zbierania logów z Vector do VictoriaLogs"
time vector

sleep 10

echo "Benchmark przetwarzania logów w VictoriaLogs"
time curl -X POST -H "Content-Type: application/json" --data-binary @- "http://localhost:8420/api/v1/query" <<EOF
{
  "sql": "SELECT COUNT(*) FROM my_logs"
}
EOF

podman stop vector-container
podman stop victorialogs-container
podman rm vector-container
podman rm victorialogs-container

