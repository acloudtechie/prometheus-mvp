set -e
bosh -n -d prometheus deploy prometheus.yml \
     -o ops/prometheus-exporter-ops.yml \
     -o ops/alertmanager-slack-receiver.yml \
     -o ops/monitor-http-probe.yml \
     -o ops/prometheus-config-ops.yml \
     --vars-store prometheus-params.yml
