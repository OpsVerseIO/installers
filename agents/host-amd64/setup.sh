#!/bin/bash

# Copyright 2022 OpsVerse
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SERVICE_NAME=opsverse-agent
SERVICE_FILE=/etc/systemd/system/${SERVICE_NAME}.service
SYSV_SERVICE_FILE=/etc/init.d/${SERVICE_NAME}

NODE_EXPORTER_SERVICE_NAME=node_exporter
NODE_EXPORTER_SERVICE_FILE=/etc/systemd/system/${NODE_EXPORTER_SERVICE_NAME}.service
NODE_EXPORTER_SYSV_SERVICE_FILE=/etc/init.d/${NODE_EXPORTER_SERVICE_NAME}

# Parse CLI args
while [[ $# -gt 0 ]]; do
  case $1 in
    -m|--metrics-host)
      METRICS_HOST="$2"
      shift # past argument
      shift # past value
      ;;
    -l|--logs-host)
      LOGS_HOST="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--traces-collector-host)
      TRACES_HOST="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--password)
      PASS="$2"
      shift # past argument
      shift # past value
      ;;
    --help)
      HELP=true
      shift # past argument
      ;;
    *)
      echo "Unknown parameter passed: $1"
      exit 1 ;;
  esac
done

# Show help, if necessary, and exit
if [ "$HELP" = true ] || [ -z $METRICS_HOST ] || [ -z $LOGS_HOST ] || [ -z $PASS ] ; then
  echo "Installs the OpsVerse Agent on your machine"
  echo ""
  echo "Usage: sudo installer -- [OPTIONS]" 
  echo ""
  echo "Arguments:"
  echo "  -m, --metrics-host             Your Prometheus-compatible metrics host"
  echo "  -l, --logs-host                Your Loki host"
  echo "  -t, --traces-collector-host    Your traces collector host (optional)"
  echo "  -p, --password                 Your ObserveNow instance auth password"
  echo ""
  echo "Example:"
  echo "  sudo installer -- -m metrics-foobar.mysubdomain.com \\"
  echo "           -l logs-foobar.mysubdomain.com \\"
  echo "           -t traces-collector-foobar.mysubdomain.com \\"
  echo "           -p somepass" 

  exit 0
fi


# move executable and config to appropriate directories
mkdir -p /usr/local/bin/ /etc/opsverse/targets
cp -f ./agent-v0.13.1-linux-amd64 /usr/local/bin/opsverse-telemetry-agent
cp -f ./node_exporter /usr/local/bin/node_exporter
cp -f ./agent-config.yaml /etc/opsverse/
cp -f ./targets-node-exporter.json /etc/opsverse/targets/node-exporter.json
chmod +x /usr/local/bin/opsverse-telemetry-agent
chmod +x /usr/local/bin/node_exporter

# Replace variables in agent config file
HOSTNAME=$(hostname)
B64PASS=$(echo -n "devopsnow:${PASS}" | base64)
sed -i "s/__METRICS_HOST__/${METRICS_HOST}/g" /etc/opsverse/agent-config.yaml
sed -i "s/__LOGS_HOST__/${LOGS_HOST}/g" /etc/opsverse/agent-config.yaml
sed -i "s/__TRACES_HOST__/${TRACES_COLLECTOR_HOST}/g" /etc/opsverse/agent-config.yaml
sed -i "s/__PASSWORD__/${PASS}/g" /etc/opsverse/agent-config.yaml
sed -i "s/__HOST__/${HOSTNAME}/g" /etc/opsverse/agent-config.yaml

if [ -f /lib/systemd/systemd ]; then
  # Setup the systemd service file
  if [ -f ${SERVICE_FILE} ]; then
    systemctl stop ${SERVICE_NAME}.service
    systemctl disable ${SERVICE_NAME}.service

    echo "Backing up existing service (${SERVICE_FILE}) file to /tmp"
    cp -f ${SERVICE_FILE} /tmp
  fi
  cp -f ./${SERVICE_NAME}.service ${SERVICE_FILE}

  if [ -f ${NODE_EXPORTER_SERVICE_FILE} ]; then
    systemctl stop ${NODE_EXPORTER_SERVICE_NAME}.service
    systemctl disable ${NODE_EXPORTER_SERVICE_NAME}.service

    echo "Backing up existing service (${NODE_EXPORTER_SERVICE_FILE}) file to /tmp"
    cp -f ${NODE_EXPORTER_SERVICE_FILE} /tmp
  fi
  cp -f ./${NODE_EXPORTER_SERVICE_NAME}.service ${NODE_EXPORTER_SERVICE_FILE}

  # opsverse-agent service
  systemctl enable ${SERVICE_NAME}.service
  systemctl start ${SERVICE_NAME}.service

  # node_exporter service
  systemctl enable ${NODE_EXPORTER_SERVICE_NAME}.service
  systemctl start ${NODE_EXPORTER_SERVICE_NAME}.service

elif [ -f /sbin/init ]; then
  
  echo "Could not find systemd on machine... falling back to SysV"

  # Setup the sysv init file
  if [ -f ${SYSV_SERVICE_FILE} ]; then
    chmod 755 ${SYSV_SERVICE_FILE}
    /etc/init.d/${SERVICE_NAME} stop

    echo "Backing up existing service (${SYSV_SERVICE_FILE}) file to /tmp"
    cp -f ${SYSV_SERVICE_FILE} /tmp
  fi
  cp -f ./${SERVICE_NAME}.sysv ${SYSV_SERVICE_FILE}
  chmod 755 ${SYSV_SERVICE_FILE}

  if [ -f ${NODE_EXPORTER_SYSV_SERVICE_FILE} ]; then
    chmod 755 ${NODE_EXPORTER_SYSV_SERVICE_FILE}
    /etc/init.d/${NODE_EXPORTER_SERVICE_NAME} stop

    echo "Backing up existing service (${NODE_EXPORTER_SYSV_SERVICE_FILE}) file to /tmp"
    cp -f ${NODE_EXPORTER_SYSV_SERVICE_FILE} /tmp
  fi
  cp -f ./${NODE_EXPORTER_SERVICE_NAME}.sysv ${NODE_EXPORTER_SYSV_SERVICE_FILE}
  chmod 755 ${NODE_EXPORTER_SYSV_SERVICE_FILE}

  # opsverse-agent service
  chkconfig opsverse-agent on
  /etc/init.d/${SERVICE_NAME} start

  # node_exporter service
  chkconfig node_exporter on
  /etc/init.d/${NODE_EXPORTER_SERVICE_NAME} start

else

  echo "Could not find an init system on your machine. Exiting."

fi
