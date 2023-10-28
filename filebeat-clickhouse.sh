#!/bin/bash

# Ścieżka do lokalnego pliku z logami
LOG_FILE="logfile.log"

# Utwórz przykładowy plik konfiguracyjny dla Filebeat
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

# Kopiuj plik z logami do katalogu, który będzie dostępny dla kontenera Filebeat
mkdir -p /var/log/app
cp "$LOG_FILE" /var/log/app/app.log

# Uruchom kontener z ClickHouse
podman run -d --name clickhouse-container --ulimit nofile=262144:262144 yandex/clickhouse-server

# Oczekaj chwilę na uruchomienie kontenera ClickHouse
sleep 10

# Uruchom kontener z Filebeat
podman run -d --name filebeat-container docker.elastic.co/beats/filebeat:latest filebeat -e -strict.perms=false -E filebeat.config.inputs.path=filebeat-config.yml

# Oczekaj chwilę na uruchomienie kontenera Filebeat
sleep 10

# Benchmark zbierania logów za pomocą Filebeat
echo "Benchmark zbierania logów za pomocą Filebeat"
time filebeat -e -strict.perms=false

# Oczekaj chwilę, aż Filebeat rozpocznie zbieranie logów
sleep 10

# Benchmark przetwarzania logów w ClickHouse
echo "Benchmark przetwarzania logów w ClickHouse"
time clickhouse-client --query "SELECT COUNT(*) FROM logs"

# Zatrzymaj i usuń kontenery
podman stop filebeat-container
podman stop clickhouse-container
podman rm filebeat-container
podman rm clickhouse-container

