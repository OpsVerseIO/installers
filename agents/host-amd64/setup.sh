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

ETC_OPSVERSE="/etc/opsverse"
OPSVERSE_AGENT_CONFIG_FULLPATH=${ETC_OPSVERSE}/agent-config.yaml

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
    -f|--force-config-override)
      FORCE_CONFIG_OVERRIDE=true
      shift # past argument
      ;;
    --no-config-override)
      NO_CONFIG_OVERRIDE=true
      shift # past argument
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
  echo "  -f, --force-config-override    If you already have an existing /etc/config/agent-config.yaml,"
  echo "                                 this option will force override it with the default without"
  echo "                                 prompting"
  echo "  --no-config-override           If you already have an existing /etc/config/agent-config.yaml,"
  echo "                                 this option will use that instead of prompting to choose. If"
  echo "                                 used with -f, this option (--no-config-override) will take priority"
  echo ""
  echo "Example:"
  echo "  sudo installer -- -m metrics-foobar.mysubdomain.com \\"
  echo "           -l logs-foobar.mysubdomain.com \\"
  echo "           -t traces-collector-foobar.mysubdomain.com \\"
  echo "           -p somepass" 

  if [ "$HELP" != "true" ] && [ "$NO_CONFIG_OVERRIDE" == "true" ] ; then
    if [ -f ${OPSVERSE_AGENT_CONFIG_FULLPATH} ] ; then
      echo "Required observabiltiy endpoints not passed, but since --no-config-override is being used, continuing installation with existing ${OPSVERSE_AGENT_CONFIG_FULLPATH}..."
    else
      echo "--no-config-override was passed, but ${OPSVERSE_AGENT_CONFIG_FULLPATH} doesn't exist. Exiting."
      exit 0
    fi
  else
    exit 0
  fi
fi

function install_agent_config () {
  cp -f ./agent-config.yaml ${OPSVERSE_AGENT_CONFIG_FULLPATH}

  # Replace variables in agent config file
  HOSTNAME=$(hostname)
  B64PASS=$(echo -n "devopsnow:${PASS}" | base64)
  sed -i "s/__METRICS_HOST__/${METRICS_HOST}/g" ${OPSVERSE_AGENT_CONFIG_FULLPATH}
  sed -i "s/__LOGS_HOST__/${LOGS_HOST}/g" ${OPSVERSE_AGENT_CONFIG_FULLPATH}
  sed -i "s/__TRACES_HOST__/${TRACES_COLLECTOR_HOST}/g" ${OPSVERSE_AGENT_CONFIG_FULLPATH}
  sed -i "s/__PASSWORD__/${PASS}/g" ${OPSVERSE_AGENT_CONFIG_FULLPATH}
  sed -i "s/__HOST__/${HOSTNAME}/g" ${OPSVERSE_AGENT_CONFIG_FULLPATH}
}

if [ -f ${OPSVERSE_AGENT_CONFIG_FULLPATH} ] ; then

  echo "An agent config at ${OPSVERSE_AGENT_CONFIG_FULLPATH} already exists..."

  if [ "$NO_CONFIG_OVERRIDE" == "true" ] ; then
    echo "--no-config-override option passed, so we'll use the existing ${OPSVERSE_AGENT_CONFIG_FULLPATH} ..."
  else
    if [ "$FORCE_CONFIG_OVERRIDE" != "true" ] ; then
      while true ; do
        echo ""
        echo "There is already an existing agent config at ${OPSVERSE_AGENT_CONFIG_FULLPATH}."
        echo "Please select one of the following options:"
        echo " (o) - to (o)verride it with the defaults"
        echo " (e) - to use the (e)xisting config"
        echo " (v) - to (v)iew the diff"
        read -p "Enter option: " oev
        case $oev in
          o)
            echo "Using a default agent config file..."
            install_agent_config
            break
            ;;
          e)
            echo "Using existing ${OPSVERSE_AGENT_CONFIG_FULLPATH}..."
            break
            ;;
          v)
            diff ${OPSVERSE_AGENT_CONFIG_FULLPATH} ./agent-config.yaml
            ;;
          *)
            echo "Invalid choice..."
            ;;
        esac
      done
    else
      echo "--force-config-override option passed, so we'll use a default agent config file..."
      install_agent_config
    fi
  fi

else
  install_agent_config
fi

# move executable and config to appropriate directories
mkdir -p /usr/local/bin/ /etc/opsverse/targets
cp -f ./agent-v0.13.1-linux-amd64 /usr/local/bin/opsverse-telemetry-agent
cp -f ./node_exporter /usr/local/bin/node_exporter
cp -f ./targets-node-exporter.json ${ETC_OPSVERSE}/targets/node-exporter.json
chmod +x /usr/local/bin/opsverse-telemetry-agent
chmod +x /usr/local/bin/node_exporter

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
