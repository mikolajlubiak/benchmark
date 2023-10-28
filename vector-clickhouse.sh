#!/bin/bash

# Ścieżka do lokalnego pliku z logami
LOG_FILE="logfile.log"

# Utwórz przykładowy plik konfiguracyjny dla Vector
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

# Kopiuj plik z logami do katalogu, który będzie dostępny dla kontenera Vector
mkdir -p /var/log/vector
cp "$LOG_FILE" /var/log/vector/

# Uruchom kontener z ClickHouse
podman run -d --name clickhouse-container --ulimit nofile=262144:262144 yandex/clickhouse-server

# Oczekaj chwilę na uruchomienie kontenera ClickHouse
sleep 10

# Uruchom kontener z Vector
podman run -d --name vector-container -v vector-config.toml:/etc/vector/vector.toml -v /var/log/vector:/var/log/vector timberio/vector:latest vector --config /etc/vector/vector.toml

# Oczekaj chwilę na uruchomienie kontenera Vector
sleep 10

# Benchmark zbierania logów
echo "Benchmark zbierania logów z Vector do ClickHouse"
time vector

# Oczekaj chwilę, aż Vector rozpocznie zbieranie logów
sleep 10

# Benchmark przetwarzania logów w ClickHouse
echo "Benchmark przetwarzania logów w ClickHouse"
time clickhouse-client --query "SELECT COUNT(*) FROM logs"

# Zatrzymaj i usuń kontenery
podman stop vector-container
podman stop clickhouse-container
podman rm vector-container
podman rm clickhouse-container

