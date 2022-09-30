#!/bin/sh

##
# Pre-req for env:
#  GRAFANA_TOKEN (e.g., awafawwgasdgasgsgd==)
#  GRAFANA_HOST (e.g., example.com)
#
# Required tools on machine:
#  - curl
#  - jq
#
# Returns:
#  - downloaded alerts at "./downloaded-alerts.json"
#  - downloaed dashboards at "./downloaded-dashboards/"
##

### alerts ###
curl -X GET \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  "https://${GRAFANA_HOST}/api/ruler/grafana/api/v1/rules" | jq > 'downloaded-alerts.json'

### dashboards ###
# See https://gist.github.com/crisidev/bd52bdcc7f029be2f295
dl_db_path="./downloaded-dashboards"
mkdir -p $dl_db_path
for dash in $(curl -H "Authorization: Bearer $GRAFANA_TOKEN" "https://${GRAFANA_HOST}/api/search?query=&" | jq -r '.[] | select(.type == "dash-db") | .uid'); do
  curl -H "Authorization: Bearer $GRAFANA_TOKEN" -s "https://${GRAFANA_HOST}/api/search?query=&" 1>/dev/null

  dash_path="$dl_db_path/$dash.json"
  curl -H "Authorization: Bearer $GRAFANA_TOKEN" -s "https://${GRAFANA_HOST}/api/dashboards/uid/$dash" | jq -r . > $dash_path 
  jq -r .dashboard $dash_path > $dl_db_path/dashboard.json 

  title=$(jq -r .dashboard.title $dash_path)
  folder="$(jq -r '.meta.folderTitle' $dash_path)"
  mkdir -p "$dl_db_path/$folder"
  mv -f $dl_db_path/dashboard.json "$dl_db_path/$folder/${title}.json"
  echo "exported $folder/${title}.json"
done
