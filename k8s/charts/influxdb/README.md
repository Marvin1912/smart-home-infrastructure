# InfluxDB

InfluxDB 2.x instance used by Home Assistant, Telegraf, the `applications`
workload (a.k.a. `backend`) and Grafana for time-series storage.

## In-cluster access

| Setting   | Value                                                       |
|-----------|-------------------------------------------------------------|
| URL       | `http://influxdb-service.default.svc.cluster.local:8086`    |
| Org       | `wildfly_domain`                                            |
| UI / HTTP | `http://influxdb.home-lab.com` (via Traefik IngressRoute)   |

The chart provisions a `ClusterIP` Service named `influxdb-service` in the
`default` namespace; in-cluster workloads connect via the FQDN above.

## Buckets

Buckets are created by the post-install setup job
(`templates/setup-job.yaml` + `templates/configmap.yaml`).

| Bucket            | Retention | Purpose                                                        |
|-------------------|-----------|----------------------------------------------------------------|
| `costs`           | infinite  | Cost / consumption series imported by the `applications` jobs. |
| `sensor_data`     | 212 days  | Raw sensor readings written by Home Assistant.                 |
| `sensor_data_30m` | infinite  | 30-minute downsamples of `sensor_data` (task target).          |
| `system_metrics`  | infinite  | Host/container metrics written by Telegraf.                    |

A scheduled Flux task `Downsample to 30m means` (every 7d, active) aggregates
`sensor_data` into 30-minute means. A second task `Downsample All` exists in
`inactive` state for one-off back-fills.

## `sensor_data` schema

Home Assistant writes each entity into a measurement named after its unit of
measurement. Tags identify the source entity; the numeric reading lives in the
`value` field.

Example — outdoor temperature (used by the backend `/climate/readings`
endpoint):

| Element              | Value                    |
|----------------------|--------------------------|
| Bucket               | `sensor_data`            |
| Measurement (`_measurement`) | `°C`             |
| Tag `entity_id`      | `draussen_temperature`   |
| Tag `friendly_name`  | `Draußen`                |
| Field (`_field`)     | `value`                  |

Sample Flux query:

```flux
from(bucket: "sensor_data")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "°C")
  |> filter(fn: (r) => r.entity_id == "draussen_temperature")
  |> filter(fn: (r) => r._field == "value")
```

## Credentials

The read/write token used by in-cluster workloads is stored in the
`applications-credentials` SealedSecret (`k8s/secrets/secret_applications.json`)
under the key `INFLUX_TOKEN`.

A new workload that needs to query InfluxDB should:

1. Reference the existing secret rather than minting a new token:

   ```yaml
   env:
     - name: INFLUX_URL
       value: "http://influxdb-service.default.svc.cluster.local:8086"
     - name: INFLUX_ORG
       value: "wildfly_domain"
     - name: INFLUX_TOKEN
       valueFrom:
         secretKeyRef:
           name: applications-credentials
           key: INFLUX_TOKEN
   ```

2. Verify the env vars are present after rollout:

   ```bash
   kubectl describe deployment <name> -n default | grep INFLUX_
   ```

The `applications` deployment (`k8s/charts/applications/templates/deployment.yaml`)
is the canonical example.

The admin token / admin password used by InfluxDB itself live in the separate
`influxdb-credentials` SealedSecret (`k8s/secrets/secret_influxdb.json`) and
should not be used by application workloads.
