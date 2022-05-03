#!/bin/bash

###############################################################################
# A script to assist with installing prometheus exporters on 64-bit Linux
# machines
#
# Assumes you are running on a 64-bit Linux machine with systemd enabled
# by default
#
# Will set up a new service "prom-<servicename>-exporter"
###############################################################################

# Parse CLI args
while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--exporter)
      EXPORTER="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      HELP=true
      shift # past argument
      ;;
    *)
      echo "Unknown parameter passed: $1"
      exit 1 ;;
  esac
done

# Show help, if necessary, and exit
if [ "$HELP" = true ] || [ "$EXPORTER" != "mysqld" -a "$EXPORTER" != "mongodb" -a "$EXPORTER" != "redis" ]; then
  echo "Installs a prometheus exporter on your machine"
  echo ""
  echo "Usage: sudo ./install-exporter.sh -e <exporter>" 
  echo ""
  echo "Arguments:"
  echo "  -e, --exporter                 The opensource prometheus exporter to install on your machine"
  echo ""
  echo "Current list of supported exporters:"
  echo "  - mongodb"
  echo "  - mysqld"
  echo "  - redis"
  echo ""
  echo "Example:"
  echo "  sudo ./install-exporter.sh -e mysqld"

  exit 0
fi

function download_exporter () {

  if [ "$EXPORTER" == "mongodb" ]; then
    EXPORTER_VERSION="0.32.0"
    EXPORTER_BASE_NAME="mongodb_exporter-${EXPORTER_VERSION}.linux-amd64"
    EXPORTER_DL_URL="https://github.com/percona/mongodb_exporter/releases/download/v${EXPORTER_VERSION}/${EXPORTER_BASE_NAME}.tar.gz"

    wget ${EXPORTER_DL_URL}
    tar -xzf ${EXPORTER_BASE_NAME}.tar.gz
    cp ${EXPORTER_BASE_NAME}/mongodb_exporter /usr/local/bin/
    chmod +x /usr/local/bin/mongodb_exporter

    # cleanup what was downloaded
    rm -rf ${EXPORTER_BASE_NAME}*
  fi

  if [ "$EXPORTER" == "mysqld" ]; then
    EXPORTER_VERSION="0.14.0"
    EXPORTER_BASE_NAME="mysqld_exporter-${EXPORTER_VERSION}.linux-amd64"
    EXPORTER_DL_URL="https://github.com/prometheus/mysqld_exporter/releases/download/v${EXPORTER_VERSION}/${EXPORTER_BASE_NAME}.tar.gz"

    wget ${EXPORTER_DL_URL}
    tar -xzf ${EXPORTER_BASE_NAME}.tar.gz
    cp ${EXPORTER_BASE_NAME}/mysqld_exporter /usr/local/bin/
    chmod +x /usr/local/bin/mysqld_exporter

    # cleanup what was downloaded
    rm -rf ${EXPORTER_BASE_NAME}*
  fi

  if [ "$EXPORTER" == "redis" ]; then
    EXPORTER_VERSION="1.37.0"
    EXPORTER_BASE_NAME="redis_exporter-v${EXPORTER_VERSION}.linux-amd64"
    EXPORTER_DL_URL="https://github.com/oliver006/redis_exporter/releases/download/v${EXPORTER_VERSION}/${EXPORTER_BASE_NAME}.tar.gz"

    wget ${EXPORTER_DL_URL}
    tar -xzf ${EXPORTER_BASE_NAME}.tar.gz
    cp ${EXPORTER_BASE_NAME}/redis_exporter /usr/local/bin/
    chmod +x /usr/local/bin/redis_exporter

    # cleanup what was downloaded
    rm -rf ${EXPORTER_BASE_NAME}*
  fi
}

function set_exporter_custom_confs () {

  if [ "$EXPORTER" == "mysqld" ]; then
    cat << EOF > /etc/opsverse/exporters/mysqld/.my.cnf
[client]
host=localhost
port=3306
user=root
password="my-secret-pw"
EOF
  fi

}

function set_exporter_systemd () {

  if [ -f ${EXPORTER_SERVICE_FILE} ]; then
    systemctl stop ${EXPORTER_SERVICE_NAME}.service
    systemctl disable ${EXPORTER_SERVICE_NAME}.service

    echo "Backing up existing service ${EXPORTER_SERVICE_FILE} file to /tmp"
    cp -f ${EXPORTER_SERVICE_FILE} /tmp
  fi

  if [ "$EXPORTER" == "mongodb" ]; then
    cat << EOF > $EXPORTER_SERVICE_FILE
[Unit]
Description=Prometheus MongoDB Exporter

[Service]
User=root
ExecStart=/usr/local/bin/mongodb_exporter --mongodb.uri=mongodb://localhost:27017/admin --collect-all --compatible-mode
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  fi

  if [ "$EXPORTER" == "mysqld" ]; then
    cat << EOF > $EXPORTER_SERVICE_FILE
[Unit]
Description=Prometheus MySQL Server Exporter

[Service]
User=root
ExecStart=/usr/local/bin/mysqld_exporter --config.my-cnf=/etc/opsverse/exporters/mysqld/.my.cnf 
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  fi

  if [ "$EXPORTER" == "redis" ]; then
    cat << EOF > $EXPORTER_SERVICE_FILE
[Unit]
Description=Prometheus Redis Exporter

[Service]
User=root
ExecStart=/usr/local/bin/redis_exporter --redis.addr=redis://localhost:6379
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  fi

  systemctl enable ${EXPORTER_SERVICE_NAME}.service
  systemctl start ${EXPORTER_SERVICE_NAME}.service

}

function set_exporter_scrape_target () {

  if [ "$EXPORTER" == "mongodb" ]; then
    cat << EOF > /etc/opsverse/targets/${EXPORTER}-exporter.json
[
  {
    "labels": {
      "job": "integrations/mongodb-exporter"
    },
    "targets": [
      "localhost:9216"
    ]
  }
]
EOF
  fi

  if [ "$EXPORTER" == "mysqld" ]; then
    cat << EOF > /etc/opsverse/targets/${EXPORTER}-exporter.json
[
  {
    "labels": {
      "job": "integrations/mysqld-exporter"
    },
    "targets": [
      "localhost:9104"
    ]
  }
]
EOF
  fi

  if [ "$EXPORTER" == "redis" ]; then
    cat << EOF > /etc/opsverse/targets/${EXPORTER}-exporter.json
[
  {
    "labels": {
      "job": "integrations/redis-exporter"
    },
    "targets": [
      "localhost:9121"
    ]
  }
]
EOF
  fi

}

function exporter_setup () {
  download_exporter
  set_exporter_custom_confs
  set_exporter_systemd
  set_exporter_scrape_target
}

EXPORTER_SERVICE_NAME=prom-${EXPORTER}-exporter
EXPORTER_SERVICE_FILE=/etc/systemd/system/${EXPORTER_SERVICE_NAME}.service

# move executable and config to appropriate directories
mkdir -p /usr/local/bin/ /etc/opsverse/exporters/${EXPORTER} /etc/opsverse/targets

exporter_setup
