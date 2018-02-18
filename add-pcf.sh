 #!/bin/bash
set -e
PARAM_FILE="prometheus-params.yml"
EXPORTER_OPS_FILE="prometheus-exporter-ops.yml"

validateStringInput(){
    if [ -z $1 ]; then
        echo "Invalid parameter entered" >&2; exit 1
    fi
}

#expecting a single integer input parameter
validateIntegerInput(){
    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]] ; then
        echo "Invalid parameter entered: Not a number" >&2; exit 1
    fi
}

echo -n "The number of environment(s) to add to the monitoring [ENTER]: "
read envNum
validateIntegerInput $envNum

temp=$(tail -1 ${PARAM_FILE})
start=${temp:3:1}

for (( c=1; c<=$envNum; c++ )) do
  index=$((c+start))

  echo -n "Enter environment name: [ENTER]: "
  read pcfName
  validateStringInput $pcfName

  echo -n "Enter pcf system domain (Ex: sys.example.com): [ENTER]: "
  read sysDomain
  validateStringInput $sysDomain

  echo -n "Enter cf exporter secret: [ENTER]: "
  read cfExporterSecret
  validateStringInput $cfExporterSecret

  echo -n "Enter firehose exporter secret: [ENTER]: "
  read firehoseExporterSecret
  validateStringInput $firehoseExporterSecret

  cat >> ./${PARAM_FILE} <<EOL
pcf${index}_metrics_environment: $pcfName
pcf${index}_metron_deployment_name: cf
pcf${index}_system_domain: $sysDomain
pcf${index}_traffic_controller_external_port: 443
pcf${index}_uaa_clients_cf_exporter_secret: $cfExporterSecret
pcf${index}_uaa_clients_firehose_exporter_secret: $firehoseExporterSecret
EOL

    cat >> ./ops/${EXPORTER_OPS_FILE} <<EOL
- type: replace
  path: /instance_groups/-
  value:
    name: $pcfName
    azs:
      - z1
    instances: 1
    vm_type: default
    stemcell: default
    networks:
      - name: default
    jobs:
      - name: firehose_exporter
        release: prometheus
        properties:
          firehose_exporter:
            doppler:
              url: wss://doppler.((pcf${index}_system_domain)):((pcf${index}_traffic_controller_external_port))
              subscription_id: "((pcf${index}_metrics_environment))"
              max_retry_count: 300
            uaa:
              url: https://uaa.((pcf${index}_system_domain))
              client_id: firehose_exporter
              client_secret: "((pcf${index}_uaa_clients_firehose_exporter_secret))"
            metrics:
              environment: "((pcf${index}_metrics_environment))"
            skip_ssl_verify: ((skip_ssl_verify))
      - name: cf_exporter
        release: prometheus
        properties:
          cf_exporter:
            cf:
              api_url: https://api.((pcf${index}_system_domain))
              client_id: cf_exporter
              client_secret: "((pcf${index}_uaa_clients_cf_exporter_secret))"
              deployment_name: ((pcf${index}_metron_deployment_name))
            metrics:
              environment: "((pcf${index}_metrics_environment))"
            skip_ssl_verify: ((skip_ssl_verify))
EOL
  done

