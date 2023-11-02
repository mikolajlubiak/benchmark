#!/bin/sh

echo "rozpoczynam benchmark-write..."
time cat /opt/example.log | vector -v --allocation-tracing
