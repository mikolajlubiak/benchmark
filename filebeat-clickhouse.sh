#!/bin/bash

LOG_FILE="logfile.log"

cat <<EOF > filebeat-config.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/app/*.log

output:
  clickhouse:
    host: "clickhouse-host"
    port: 8123
    database: "my_logs"
    table: "logs"
    username: "your_username"
    password: "your_password"
EOF

mkdir -p /var/log/app
cp "$LOG_FILE" /var/log/app/app.log

podman run -d --name clickhouse-container --ulimit nofile=262144:262144 yandex/clickhouse-server

sleep 10

podman run -d --name filebeat-container -v filebeat-config.yml:/usr/share/filebeat/filebeat.yml -v /var/log/app:/var/log/app docker.elastic.co/beats/filebeat:latest -e -strict.perms=false

sleep 10

echo "Benchmark zbierania logów za pomocą Filebeat"
podman exec -it filebeat-container filebeat -e -strict.perms=false

sleep 10

echo "Benchmark przetwarzania logów w ClickHouse"
time clickhouse-client --query "SELECT COUNT(*) FROM logs"

podman stop filebeat-container
podman stop clickhouse-container
podman rm filebeat-container
podman rm clickhouse-container
