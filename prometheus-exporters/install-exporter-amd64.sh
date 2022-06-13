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

###
# A script to assist with installing prometheus exporters on 64-bit Linux
# machines
#
# Assumes you are running on a 64-bit Linux machine with systemd enabled
# by default
#
# Will set up a new service "prom-<servicename>-exporter"
###

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
if [ "$HELP" = true ] || [ "$EXPORTER" != "mysqld" -a "$EXPORTER" != "mongodb" -a "$EXPORTER" != "redis" -a "$EXPORTER" != "jmx" ]; then
  echo "Installs a prometheus exporter on your machine"
  echo ""
  echo "Usage: sudo ./install-exporter.sh -e <exporter>" 
  echo ""
  echo "Arguments:"
  echo "  -e, --exporter                 The opensource prometheus exporter to install on your machine"
  echo ""
  echo "Current list of supported exporters:"
  echo "  - jmx"
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

  if [ "$EXPORTER" == "jmx" ]; then
    EXPORTER_VERSION="0.16.1"
    EXPORTER_BASE_NAME="jmx_prometheus_javaagent-${EXPORTER_VERSION}"
    EXPORTER_DL_URL="https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${EXPORTER_VERSION}/${EXPORTER_BASE_NAME}.jar"

    wget ${EXPORTER_DL_URL}
    cp ${EXPORTER_BASE_NAME}.jar /usr/local/bin/
    chmod +x /usr/local/bin/${EXPORTER_BASE_NAME}.jar

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

  if [ "$EXPORTER" == "jmx" ]; then
    cat << EOF > /etc/opsverse/exporters/jmx/config.yaml
rules:
- pattern: ".*"
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


  # Wrapped in this condition because some exporters (like the
  # jmx agent), don't need to run as services
  if [ -f ${EXPORTER_SERVICE_FILE} ]; then
    systemctl enable ${EXPORTER_SERVICE_NAME}.service
    systemctl start ${EXPORTER_SERVICE_NAME}.service
  fi

}

# returns true (0) if exporter needs a sysv init script
function exporter_needs_sysv () {

  if [ "$1" == "redis" ] || [ "$1" == "mysqld" ] || [ "$1" == "mongodb" ]; then
    return 0
  fi

  return 1
}

function set_exporter_sysv () {

  if [ -f ${EXPORTER_SYSV_SCRIPT} ]; then
    chkconfig ${EXPORTER_SERVICE_NAME} off
    ${EXPORTER_SYSV_SCRIPT} stop

    echo "Backing up existing service ${EXPORTER_SYSV_SCRIPT} file to /tmp"
    cp -f ${EXPORTER_SYSV_SCRIPT} /tmp
  fi

  if exporter_needs_sysv $EXPORTER; then

    EXPORTER_LOG="/var/log/${EXPORTER_SERVICE_NAME}.log"

    if [ "$EXPORTER" == "mysqld" ]; then
      EXPORTER_CONFIG="/etc/opsverse/exporters/mysqld/.my.cnf"
      EXPORTER_COMMAND="/usr/local/bin/mysqld_exporter --config.my-cnf=/etc/opsverse/exporters/mysqld/.my.cnf"
      EXPORTER_KILLPROC="mysqld_exporter"
    fi

    if [ "$EXPORTER" == "mongodb" ]; then
      EXPORTER_CONFIG="N/A"
      EXPORTER_COMMAND="/usr/local/bin/mongodb_exporter --mongodb.uri=mongodb://localhost:27017/admin --collect-all --compatible-mode"
      EXPORTER_KILLPROC="mongodb_exporter"
    fi

    if [ "$EXPORTER" == "redis" ]; then
      EXPORTER_CONFIG="N/A"
      EXPORTER_COMMAND="/usr/local/bin/redis_exporter --redis.addr=redis://localhost:6379"
      EXPORTER_KILLPROC="redis_exporter"
    fi

    cat << EOF > $EXPORTER_SYSV_SCRIPT
#!/bin/bash
#
# $EXPORTER_SERVICE_NAME 	This loads the $EXPORTER_SERVICE_NAME
#
# chkconfig: 2345 99 01
# description: Initializes $EXPORTER_SERVICE_NAME
# config: $EXPORTER_CONFIG
#
### BEGIN INIT INFO
# Provides:          $EXPORTER_SERVICE_NAME
# Short-Description: Initializes $EXPORTER_SERVICE_NAME
# Description:       Initializes $EXPORTER_SERVICE_NAME for metrics to prometheus
### END INIT INFO

# Copyright 2022 OpsVerse
#
# Based in part on a shell script by
# Andreas Dilger <adilger@turbolinux.com>  Sep 26, 2001

# Source function library.
. /etc/rc.d/init.d/functions


usage ()
{
	echo $"Usage: \$0 {start|stop|status|restart}" 1>&2
	RETVAL=2
}

start ()
{
	echo $"Starting $EXPORTER_SERVICE_NAME" 1>&2
	$EXPORTER_COMMAND >> ${EXPORTER_LOG} 2>&1  &
	touch /var/lock/subsys/$EXPORTER_SERVICE_NAME
	echo \$(pidof $EXPORTER_KILLPROC) > /var/run/${EXPORTER_SERVICE_NAME}.pid

	success $"$EXPORTER_SERVICE_NAME startup"
	echo
}

stop ()
{

	echo $"Stopping $EXPORTER_SERVICE_NAME" 1>&2
	killproc $EXPORTER_KILLPROC
	rm -f /var/lock/subsys/$EXPORTER_SERVICE_NAME
	rm -f /var/run/${EXPORTER_SERVICE_NAME}.pid
	echo
}

restart ()
{
	stop
	start
}

case "\$1" in
    stop) stop ;;
    status)
	    status $EXPORTER_SERVICE_NAME
	    ;;
    start) start ;;
    restart|reload|force-reload) restart ;;
    *) usage ;;
esac

exit \$RETVAL
EOF

    chmod +x ${EXPORTER_SYSV_SCRIPT}
    chkconfig ${EXPORTER_SERVICE_NAME} on
    ${EXPORTER_SYSV_SCRIPT} start

  fi

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

  if [ "$EXPORTER" == "jmx" ]; then
    cat << EOF > /etc/opsverse/targets/${EXPORTER}-exporter.json
[
  {
    "labels": {
      "job": "integrations/jmx-exporter"
    },
    "targets": [
      "localhost:9404"
    ]
  }
]
EOF
  fi

}

function exporter_setup () {
  download_exporter
  set_exporter_custom_confs

  if [ -f /lib/systemd/systemd ]; then
    set_exporter_systemd
  else
    echo "systemd not found on system... falling back to SysV"
    set_exporter_sysv
  fi

  set_exporter_scrape_target
}

EXPORTER_SERVICE_NAME=prom-${EXPORTER}-exporter
EXPORTER_SERVICE_FILE=/etc/systemd/system/${EXPORTER_SERVICE_NAME}.service
EXPORTER_SYSV_SCRIPT=/etc/init.d/${EXPORTER_SERVICE_NAME}

# move executable and config to appropriate directories
mkdir -p /usr/local/bin/ /etc/opsverse/exporters/${EXPORTER} /etc/opsverse/targets

exporter_setup
