#!/bin/bash

LOG_FILE="logfile.log"

cat <<EOF > filebeat-config.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/app/*.log

output:
  http:
    hosts: ["http://victorialogs-host:8420/api/v1/write"]
EOF

mkdir -p /var/log/app
cp "$LOG_FILE" /var/log/app/app.log

podman run -d --name victorialogs-container -p 8420:8420 victorialogs/victorialogs

sleep 10

podman run -d --name filebeat-container docker.elastic.co/beats/filebeat:latest filebeat -e -strict.perms=false -E filebeat.config.inputs.path=filebeat-config.yml

sleep 10

echo "Benchmark zbierania logów za pomocą Filebeat"
time filebeat -e -strict.perms=false

sleep 10

echo "Benchmark przetwarzania logów w VictoriaLogs"
time curl -X POST -H "Content-Type: application/json" --data-binary @- "http://localhost:8420/api/v1/query" <<EOF
{
  "sql": "SELECT COUNT(*) FROM my_logs"
}
EOF

podman stop filebeat-container
podman stop victorialogs-container
podman rm filebeat-container
podman rm victorialogs-container

