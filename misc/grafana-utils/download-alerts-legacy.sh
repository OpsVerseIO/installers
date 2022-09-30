#!/bin/sh

##
# Pre-req for env:
#  GRAFANA_TOKEN (e.g., awafawwgasdgasgsgd==)
#  GRAFANA_HOST (e.g., example.com)
#
#
# Required tools on machine:
#  - curl
#  - jq
#
# Disclaimer: Tested on Grafana v7
##

###################################
# Download alerts and alert notifications
# NOTE: this uses the legacy alerts APIs (for those instances not migrated to Grafana unified alerts)
###################################
curl -X GET \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  "https://${GRAFANA_HOST}/api/alerts" | jq > 'downloaded-alerts.json'

curl -X GET \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  "https://${GRAFANA_HOST}/api/alert-notifications" | jq > 'downloaded-alert-notifications.json'
