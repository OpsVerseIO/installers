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
if [ "$HELP" = true ] || [ "$EXPORTER" != "mysqld" ]; then
  echo "Installs a prometheus exporter on your machine"
  echo ""
  echo "Usage: sudo ./install-exporter.sh -e <exporter>" 
  echo ""
  echo "Arguments:"
  echo "  -e, --exporter                 The opensource prometheus exporter to install on your machine"
  echo ""
  echo "Current list of supported exporters:"
  echo "  - mysqld"
  echo ""
  echo "Example:"
  echo "  sudo ./install-exporter.sh -e mysqld"

  exit 0
fi

function download_mysqld_exporter () {
  MYSQL_EXPORTER_VERSION="0.14.0"
  MYSQL_EXPORTER_BASE_NAME="mysqld_exporter-${MYSQL_EXPORTER_VERSION}.linux-amd64"

  wget https://github.com/prometheus/mysqld_exporter/releases/download/v${MYSQL_EXPORTER_VERSION}/${MYSQL_EXPORTER_BASE_NAME}.tar.gz
  tar -xzf ${MYSQL_EXPORTER_BASE_NAME}.tar.gz
  cp ${MYSQL_EXPORTER_BASE_NAME}/mysqld_exporter /usr/local/bin/
  chmod +x /usr/local/bin/mysqld_exporter

  # cleanup what was downloaded
  rm -rf ${MYSQL_EXPORTER_BASE_NAME}*
}

function set_mysql_exporter_custom_confs () {

  cat << EOF > /etc/opsverse/exporters/mysqld/.my.cnf
[client]
host=localhost
port=3306
user=root
password="my-secret-pw"
EOF

}

function set_mysqld_exporter_systemd () {

  if [ -f ${EXPORTER_SERVICE_FILE} ]; then
    systemctl stop ${EXPORTER_SERVICE_NAME}.service
    systemctl disable ${EXPORTER_SERVICE_NAME}.service

    echo "Backing up existing service ${EXPORTER_SERVICE_FILE} file to /tmp"
    cp -f ${EXPORTER_SERVICE_FILE} /tmp
  fi

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

  systemctl enable ${EXPORTER_SERVICE_NAME}.service
  systemctl start ${EXPORTER_SERVICE_NAME}.service

}

function set_mysqld_exporter_scrape_target () {

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

}

function mysqld_exporter_setup () {
  download_mysqld_exporter
  set_mysql_exporter_custom_confs
  set_mysqld_exporter_systemd
  set_mysqld_exporter_scrape_target
}

EXPORTER_SERVICE_NAME=prom-${EXPORTER}-exporter
EXPORTER_SERVICE_FILE=/etc/systemd/system/${EXPORTER_SERVICE_NAME}.service

# move executable and config to appropriate directories
mkdir -p /usr/local/bin/ /etc/opsverse/exporters/${EXPORTER} /etc/opsverse/targets

# Download and move the exporter approprately
if [ "$EXPORTER" == "mysqld" ]; then
  mysqld_exporter_setup
fi