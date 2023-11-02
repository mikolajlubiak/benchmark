#!/bin/sh
docker compose up -d

sleep 10

time cat example.log | vector -v --allocation-tracing
