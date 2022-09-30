#!/bin/sh

##
# Pre-req for env:
#  GRAFANA_TOKEN (e.g., awafawwgasdgasgsgd==)
#  GRAFANA_HOST (e.g., example.com)
#  GRAFANA_ALERTS_FOLDER (e.g., 'Test'.. the alerts folder you wish to import)
#
# Required tools on machine:
#  - curl
#  - jq
##

ALERTS_JSON_PATH=./downloaded-alerts.json
NUMBER_OF_ALERTS=$(jq -c ".[\"${GRAFANA_ALERTS_FOLDER}\"] | length" ${ALERTS_JSON_PATH})

for i in `seq 0 $((NUMBER_OF_ALERTS-1))`; do
  ALERT_OBJECT=$(jq -c ".[\"$GRAFANA_ALERTS_FOLDER\"][$i] | del(.rules[0].grafana_alert.uid)" ${ALERTS_JSON_PATH})
  ALERT_NAME=$(jq -c ".[\"$GRAFANA_ALERTS_FOLDER\"][$i].name" ${ALERTS_JSON_PATH})
  echo "Creating ${ALERT_NAME}...\n"
	curl -X POST \
		-H "Authorization: Bearer ${GRAFANA_TOKEN}" \
		-H "Content-type: application/json" \
		"https://${GRAFANA_HOST}/api/ruler/grafana/api/v1/rules/${GRAFANA_ALERTS_FOLDER}" \
		-d "${ALERT_OBJECT}"
	echo "\n"
done
