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
    -t|--trace-collector-url)
      TRACE_COLLECTOR_URL="$2"
      shift # past argument
      shift # past value
      ;;
    -u|--trace-collector-user)
      TRACE_COLLECTOR_USER="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--trace-collector-pass)
      TRACE_COLLECTOR_PASS="$2"
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
if [ "$HELP" = true ] || [ "$EXPORTER" != "mysqld" -a "$EXPORTER" != "mongodb" -a "$EXPORTER" != "redis" -a "$EXPORTER" != "jmx" -a "$EXPORTER" != "nginx" -a "$EXPORTER" != "cadvisor" -a "$EXPORTER" != "vmware" -a "$EXPORTER" != "opsverse-otelcontribcol" -a "$EXPORTER" != "postgres" ]; then
  echo "Installs a prometheus exporter on your machine"
  echo ""
  echo "Usage: sudo ./install-exporter.sh -e <exporter>" 
  echo ""
  echo "Arguments:"
  echo "  -e, --exporter                 The opensource prometheus exporter to install on your machine"
  echo ""
  echo "Current list of supported exporters:"
  echo "  - cadvisor"
  echo "  - jmx"
  echo "  - mongodb"
  echo "  - mysqld"
  echo "  - nginx"
  echo "  - opsverse-otelcontribcol"
  echo "  - redis"
  echo "  - vmware"
  echo "  - postgres"
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

  if [ "$EXPORTER" == "cadvisor" ]; then
    EXPORTER_VERSION="0.39.2"
    EXPORTER_BASE_NAME="cadvisor"
    EXPORTER_DL_URL="https://github.com/google/cadvisor/releases/download/v${EXPORTER_VERSION}/${EXPORTER_BASE_NAME}"

    wget ${EXPORTER_DL_URL}
    cp ${EXPORTER_BASE_NAME} /usr/local/bin/${EXPORTER_BASE_NAME}
    chmod +x /usr/local/bin/${EXPORTER_BASE_NAME}

    # cleanup what was downloaded
    rm -rf ${EXPORTER_BASE_NAME}*
  fi


  if [ "$EXPORTER" == "nginx" ]; then
    EXPORTER_VERSION="0.10.0"
    EXPORTER_BASE_NAME="nginx-prometheus-exporter_${EXPORTER_VERSION}_linux_amd64"
    EXPORTER_DL_URL="https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${EXPORTER_VERSION}/${EXPORTER_BASE_NAME}.tar.gz"

    wget ${EXPORTER_DL_URL}
    tar -xzf ${EXPORTER_BASE_NAME}.tar.gz
    cp nginx-prometheus-exporter /usr/local/bin/
    chmod +x /usr/local/bin/nginx-prometheus-exporter

    # cleanup what was downloaded
    rm -rf ${EXPORTER_BASE_NAME}*
    rm -rf nginx-prometheus-exporter
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

  if [ "$EXPORTER" == "opsverse-otelcontribcol" ]; then
    EXPORTER_VERSION="0.34.0"
    EXPORTER_BASE_NAME="otelcontribcol_linux_amd64"
    EXPORTER_DL_URL="https://github.com/open-telemetry/opentelemetry-collector-contrib/releases/download/v${EXPORTER_VERSION}/${EXPORTER_BASE_NAME}"

    wget ${EXPORTER_DL_URL}
    mv ${EXPORTER_BASE_NAME} /usr/local/bin/opsverse-otelcontribcol
    chmod +x /usr/local/bin/opsverse-otelcontribcol

    # cleanup what was downloaded
    rm -rf ${EXPORTER_BASE_NAME}*
  fi

  if [ "$EXPORTER" == "vmware" ]; then
    EXPORTER_VERSION="0.18.3"
    EXPORTER_BASE_NAME="vmware_exporter-${EXPORTER_VERSION}"
    EXPORTER_DL_URL="https://github.com/pryorda/vmware_exporter/releases/download/v${EXPORTER_VERSION}/${EXPORTER_BASE_NAME}.tar.gz"

    wget ${EXPORTER_DL_URL}
    tar -xzf ${EXPORTER_BASE_NAME}.tar.gz
    mv ${EXPORTER_BASE_NAME} /usr/local/bin/vmware_exporter
    chmod +x /usr/local/bin/vmware_exporter/vmware_exporter/vmware_exporter.py

    # cleanup what was downloaded
    rm -rf ${EXPORTER_BASE_NAME}*
  fi

  if [ "$EXPORTER" == "postgres" ]; then
    EXPORTER_VERSION="0.10.1"
    EXPORTER_BASE_NAME="postgres_exporter-${EXPORTER_VERSION}.linux-amd64"
    EXPORTER_DL_URL="https://github.com/prometheus-community/postgres_exporter/releases/download/v${EXPORTER_VERSION}/${EXPORTER_BASE_NAME}.tar.gz"

    wget ${EXPORTER_DL_URL}
    tar -xzf ${EXPORTER_BASE_NAME}.tar.gz
    cp ${EXPORTER_BASE_NAME}/postgres_exporter /usr/local/bin
    chmod +x /usr/local/bin/postgres_exporter

    # cleanup what was downloaded
    rm -rf ${EXPORTER_BASE_NAME}*
    rm -rf postgres_exporter
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

  if [ "$EXPORTER" == "opsverse-otelcontribcol" ]; then
    if [ -z $TRACE_COLLECTOR_URL ]; then
      echo "==============="
      echo "No traces collector URL was passed in."
      echo "You can get this via the OpsVerse Admin Console:"
      echo "  'Integrations' > 'URLs and Integrations' > 'Jaeger'"
      echo "==============="
        read -p "Enter the traces collector URL (e.g., https://jane-doe.opsverse.cloud/api/v2/spans): " TRACE_COLLECTOR_URL
    fi
    if [ -z $TRACE_COLLECTOR_USER ]; then
      echo "==============="
      echo "No user for your traces collector endpoint was passed in."
      echo "You can get this via the OpsVerse Admin Console:"
      echo "  'Integrations' > 'URLs and Integrations' > 'Jaeger'"
      echo "==============="
        read -p "Enter the traces collector user (e.g., devopsnow): " TRACE_COLLECTOR_USER
    fi
    if [ -z $TRACE_COLLECTOR_PASS ]; then
      echo "==============="
      echo "No password for your traces collector endpoint was passed in. You can get this via the OpsVerse Admin Console:"
      echo "  'Integrations' > 'URLs and Integrations' > 'Jaeger'"
      echo "==============="
        read -p "Enter the traces collector password: " TRACE_COLLECTOR_PASSWORD
    fi

    TRACE_COLLECTOR_B64_AUTH=$(echo -n "${TRACE_COLLECTOR_USER}:${TRACE_COLLECTOR_PASSWORD}" | base64)
    INSTANCE=$(hostname)

    cat << EOF > /etc/opsverse/exporters/opsverse-otelcontribcol/config.yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:
  jaeger:
    protocols:
      grpc:
      thrift_compact:
      thrift_http:
  zipkin: {}
  # Dummy receiver that's never used, because a pipeline is required to have one.
  # Picked highest port in attempt to avoid conflict
  otlp/spanmetrics:
    protocols:
      grpc:
        endpoint: "localhost:65535"
processors:
  batch:
  spanmetrics:
    metrics_exporter: prometheus
    latency_histogram_buckets: [1ms, 2ms, 6ms, 10ms, 100ms, 250ms]
    dimensions:
      # If the span is missing http.method, the processor will insert
      # the http.method dimension with value 'GET'.
      # For example, in the following scenario, http.method is not present in a span and
      # so will be added as a dimension to the metric with value "GET":
      # - promexample_calls{http_method="GET",operation="/Address",service_name="shippingservice",
      #                     span_kind="SPAN_KIND_SERVER",status_code="STATUS_CODE_UNSET"} 1
      - name: http.method
        default: GET

      # If a default is not provided, the http.status_code dimension will be omitted
      # if the span does not contain http.status_code.
      # For example, consider a scenario with two spans, one span having http.status_code=200 and another
      # missing http.status_code. Two metrics would result with this configuration, one with the http_status_code
      # omitted and the other included:
      # - promexample_calls{http_status_code="200",operation="/Address",service_name="shippingservice",
      #                     span_kind="SPAN_KIND_SERVER",status_code="STATUS_CODE_UNSET"} 1
      # - promexample_calls{operation="/Address",service_name="shippingservice",span_kind="SPAN_KIND_SERVER",
      #                     status_code="STATUS_CODE_UNSET"} 1
      - name: http.status_code
      # - service.name
      # - operation
      # - span.kind
      # - status.code
  memory_limiter:
    # Same as --mem-ballast-size-mib CLI argument
    ballast_size_mib: 683
    # 80% of maximum memory up to 2G
    limit_mib: 1500
    # 25% of limit up to 2G
    spike_limit_mib: 512
    check_interval: 5s
  probabilistic_sampler:
    hash_seed: 22
    sampling_percentage: 100
  attributes/insert:
    actions:
      - key: "instance"
        value: "${INSTANCE}"
        action: insert
extensions:
  health_check: {}
  zpages: {}
exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  zipkin:
    endpoint: "${TRACE_COLLECTOR_URL}"
    headers:
      'Authorization': 'Basic ${TRACE_COLLECTOR_B64_AUTH}'
service:
  extensions: [health_check, zpages]
  pipelines:
    traces/1:
      receivers: [otlp, zipkin, jaeger]
      processors: [memory_limiter, batch, attributes/insert, spanmetrics, probabilistic_sampler]
      exporters: [zipkin]
    # This pipeline acts as a proxy to the 'metrics' pipeline below,
    # allowing for further metrics processing if required.
    metrics/spanmetrics:
      # This receiver is just a dummy and never used.
      # Added to pass validation requiring at least one receiver in a pipeline.
      receivers: [otlp/spanmetrics]
      exporters: [prometheus]
EOF
  fi

  if [ "$EXPORTER" == "vmware" ]; then
    cat << EOF > /etc/opsverse/exporters/vmware/config.yaml
default:
    vsphere_host: "vcenter"
    vsphere_user: "user"
    vsphere_password: "password"
    ignore_ssl: False
    specs_size: 5000
    fetch_custom_attributes: True
    fetch_tags: True
    fetch_alarms: True
    collect_only:
        vms: True
        vmguests: True
        datastores: True
        hosts: True
        snapshots: True
EOF
  fi

  if [ "$EXPORTER" == "postgres" ]; then
    cat << EOF > /etc/opsverse/exporters/postgres/postgres_exporter.env
DATA_SOURCE_NAME="postgresql://postgres_user:postgres_password@localhost:5432/?sslmode=disable"
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

  if [ "$EXPORTER" == "cadvisor" ]; then
    cat << EOF > $EXPORTER_SERVICE_FILE
[Unit]
Description=Prometheus Container Advisor Exporter

[Service]
User=root
ExecStart=/usr/local/bin/cadvisor -port 9338
Restart=always

[Install]
WantedBy=multi-user.target
EOF
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

  if [ "$EXPORTER" == "nginx" ]; then
    cat << EOF > $EXPORTER_SERVICE_FILE
[Unit]
Description=Prometheus Nginx Exporter

[Service]
User=root
ExecStart=/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://localhost:8080/stub_status
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  fi

  if [ "$EXPORTER" == "opsverse-otelcontribcol" ]; then
    cat << EOF > $EXPORTER_SERVICE_FILE
[Unit]
Description=OpsVerse OTel Contrib Collector

[Service]
User=root
ExecStart=/usr/local/bin/opsverse-otelcontribcol --config=/etc/opsverse/exporters/opsverse-otelcontribcol/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  fi

  if [ "$EXPORTER" == "vmware" ]; then
    cat << EOF > $EXPORTER_SERVICE_FILE
[Unit]
Description=Prometheus VMWare Exporter

[Service]
User=root
ExecStart=/usr/local/bin/vmware_exporter/vmware_exporter/vmware_exporter.py -c /etc/opsverse/exporters/vmware/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  fi

  if [ "$EXPORTER" == "postgres" ]; then
    cat << EOF > $EXPORTER_SERVICE_FILE
[Unit]
Description=Prometheus exporter for Postgresql
Wants=network-online.target
After=network-online.target

[Service]
User=postgres
Group=postgres
EnvironmentFile=/etc/opsverse/exporters/postgres/postgres_exporter.env
ExecStart=/usr/local/bin/postgres_exporter --web.listen-address=:9187 --web.telemetry-path=/metrics
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

  if [ "$1" == "redis" ] || [ "$1" == "mysqld" ] || [ "$1" == "mongodb" ] || [ "$1" == 'nginx' ] || [ "$1" == "cadvisor" ] || [ "$1" == "vmware" ] || [ "$1" == "opsverse-otelcontribcol" ] || [ "$1" == "postgres" ] ; then
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

    if [ "$EXPORTER" == "cadvisor" ]; then
      EXPORTER_CONFIG="N/A"
      EXPORTER_COMMAND="/usr/local/bin/cadvisor -port 9338"
      EXPORTER_KILLPROC="cadvisor"
    fi

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

    if [ "$EXPORTER" == "nginx" ]; then
      EXPORTER_CONFIG="N/A"
      EXPORTER_COMMAND="/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://localhost:8080/stub_status"
      EXPORTER_KILLPROC="nginx-prometheus-exporter"
    fi

    if [ "$EXPORTER" == "opsverse-otelcontribcol" ]; then
      EXPORTER_CONFIG="/etc/opsverse/exporters/opsverse-otelcontribcol/config.yaml"
      EXPORTER_COMMAND="/usr/local/bin/opsverse-otelcontribcol --config=/etc/opsverse/exporters/opsverse-otelcontribcol/config.yaml"
      EXPORTER_KILLPROC="opsverse-otelcontribcol"
    fi

    if [ "$EXPORTER" == "redis" ]; then
      EXPORTER_CONFIG="N/A"
      EXPORTER_COMMAND="/usr/local/bin/redis_exporter --redis.addr=redis://localhost:6379"
      EXPORTER_KILLPROC="redis_exporter"
    fi

    if [ "$EXPORTER" == "vmware" ]; then
      EXPORTER_CONFIG="/etc/opsverse/exporters/vmware/config.yaml"
      EXPORTER_COMMAND="/usr/local/bin/vmware_exporter/vmware_exporter/vmware_exporter.py -c /etc/opsverse/exporters/vmware/config.yaml"
      EXPORTER_KILLPROC="vmware_exporter.py"
    fi

    if [ "$EXPORTER" == "postgres" ]; then
      EXPORTER_CONFIG="/etc/opsverse/exporters/postgres/postgres_exporter.env"
      EXPORTER_COMMAND="/usr/local/bin/postgres_exporter -c /etc/opsverse/exporters/postgres/postgres_exporter.env"
      EXPORTER_KILLPROC="postgres_exporter"
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

  if [ "$EXPORTER" == "cadvisor" ]; then
    cat << EOF > /etc/opsverse/targets/${EXPORTER}-exporter.json
[
  {
    "labels": {
      "job": "integrations/cadvisor"
    },
    "targets": [
      "localhost:9338"
    ]
  }
]
EOF
  fi

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

  if [ "$EXPORTER" == "opsverse-otelcontribcol" ]; then
    cat << EOF > /etc/opsverse/targets/${EXPORTER}-exporter.json
[
  {
    "labels": {
      "job": "integrations/spanmetrics"
    },
    "targets": [
      "localhost:8889"
    ]
  }
]
EOF
  fi

  if [ "$EXPORTER" == "nginx" ]; then
    cat << EOF > /etc/opsverse/targets/${EXPORTER}-exporter.json
[
  {
    "labels": {
      "job": "integrations/nginx-prometheus-exporter"
    },
    "targets": [
      "localhost:9113"
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

  if [ "$EXPORTER" == "vmware" ]; then
    cat << EOF > /etc/opsverse/targets/${EXPORTER}-exporter.json
[
  {
    "labels": {
      "job": "integrations/vmware-exporter"
    },
    "targets": [
      "localhost:9272"
    ]
  }
]
EOF
  fi

  if [ "$EXPORTER" == "postgres" ]; then
    cat << EOF > /etc/opsverse/targets/${EXPORTER}-exporter.json
[
  {
    "labels": {
      "job": "integrations/postgres-exporter"
    },
    "targets": [
      "localhost:9187"
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
