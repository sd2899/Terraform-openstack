#!/bin/bash
set -e

PROM_FILE="/etc/prometheus/prometheus.yml"
JOB_NAME="openstack-instances"
NODE_EXPORTER_PORT="9100"

echo "[INFO] Fetching OpenStack instance IPs..."

INSTANCE_IDS=$(openstack server list -f value -c ID)

if [ -z "$INSTANCE_IDS" ]; then
  echo "[ERROR] No instances found"
  exit 1
fi

# Backup
cp "$PROM_FILE" "$PROM_FILE.bak.$(date +%F-%T)"

for ID in $INSTANCE_IDS; do
  ADDR=$(openstack server show "$ID" -f json | jq -r '.addresses')
  IP=$(echo "$ADDR" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n1)

  TARGET="$IP:$NODE_EXPORTER_PORT"

  if [ -z "$IP" ]; then
    continue
  fi

  # Skip if already exists
  if grep -q "$TARGET" "$PROM_FILE"; then
    echo "[INFO] Target already exists: $TARGET"
    continue
  fi

  echo "[INFO] Appending target: $TARGET"

  # Append target under correct job
  awk -v job="$JOB_NAME" -v target="$TARGET" '
    $0 ~ "job_name: \""job"\"" {in_job=1}
    in_job && /targets:/ {
      print
      print "        - \""target"\""
      in_job=0
      next
    }
    {print}
  ' "$PROM_FILE" > /tmp/prometheus.yml

  mv /tmp/prometheus.yml "$PROM_FILE"
done

# Reload Prometheus
if curl -s -X POST http://localhost:9090/-/reload >/dev/null; then
  echo "[INFO] Prometheus reloaded successfully"
else
  echo "[WARN] Reload failed — restart Prometheus manually"
fi

echo "[DONE] Targets appended successfully"
