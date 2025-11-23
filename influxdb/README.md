# InfluxDB Setup

This folder contains the InfluxDB configuration and setup scripts for the smart home infrastructure.

## Files

- `setup_influxdb.sh` - Script to configure InfluxDB with organizations, buckets, and tasks
- `influxdb-compose.yml` - Docker Compose configuration for InfluxDB with automated setup
- `README.md` - This documentation file

## Usage

### Start InfluxDB with automated setup:
```bash
cd influxdb
docker-compose up -d
```

### View setup progress:
```bash
docker-compose logs -f influxdb-setup
```

### Manual setup (if needed):
```bash
export INFLUX_TOKEN="your_token_here"
./setup_influxdb.sh
```

## Configuration Details

The setup creates:
- Organization: `wildfly_domain`
- Buckets: `costs`, `sensor_data`, `sensor_data_30m`, `system_metrics`
- Tasks: Data downsampling configurations

## Access InfluxDB

- URL: http://localhost:8086
- Username: marvin
- Password: password
- Organization: wildfly_domain