# Smart Home Infrastructure
This GitHub repository provides a comprehensive infrastructure setup for a smart home environment with monitoring, data collection, and automation capabilities.

The infrastructure includes various services for home automation, data persistence, monitoring, and application deployment, all orchestrated using Docker Compose.

Features:

- **Home Automation**: Home Assistant for smart home device management and automation
- **Data Persistence**: PostgreSQL database for application data and InfluxDB for time-series data
- **Monitoring**: Grafana with InfluxDB for comprehensive monitoring and visualization
- **Service Discovery**: Consul for distributed service discovery and configuration
- **Messaging**: Mosquitto MQTT broker for IoT device communication
- **Applications**: Custom applications for data processing, financial management, and user interfaces
- **Container Registry**: Local Docker registry for efficient image distribution

The basic infrastructure is represented via the following architecture description.

![Infrastructure](Infrastruktur.png?raw=true "Infrastructure")

### TLS Certificate
To be able to establish secure connections via TLS, a certificate was created for the infrastructure services.
The certificate is distributed across the services to enable secure communication.

_The certificate is purely for testing and does not contain any sensitive information._

#### Certificate Creation
The certificate files are stored in the `./consul/certs/` directory and used by various services for TLS encryption.

#### Check the validity of the certificate
- openssl x509 -inform der -in server.crt -out server.pem
- openssl x509 -in server.pem -text -noout
- Certificate -> Data -> Validity

### Local Docker Registry
A local Docker registry runs on the server so that the images can be quickly distributed within the network. In order for the builds and pushes to work towards the insecure registry (no TLS), the following must be added to the system which tries to push the images.
<pre>
/etc/docker/daemon.json

{
    "insecure-registries" : ["&lt;host&gt;:&lt;port&gt;"]
}
</pre>

## Getting Started

1. **Prerequisites**: Ensure Docker and Docker Compose are installed on your system

2. **Configuration**:
   - Update the `gradle.properties` file with your local registry address
   - Configure environment variables in `docker-compose.yml` as needed

3. **Start the infrastructure**:
   ```bash
   docker-compose up -d
   ```

4. **Access Services**:
   - Home Assistant: http://localhost:8123
   - Grafana: http://localhost:3000 (marvin/password)
   - InfluxDB: http://localhost:8086
   - Consul UI: http://localhost:8500
   - Frontend: http://localhost:3001

## Services Overview

### Database Services
- **PostgreSQL**: Primary application database
- **InfluxDB**: Time-series database for metrics and monitoring data

### Monitoring & Visualization
- **Grafana**: Data visualization and monitoring dashboard
- **Telegraf**: Metrics collection agent

### Home Automation
- **Home Assistant**: Central home automation hub
- **Mosquitto**: MQTT broker for IoT device communication

### Infrastructure
- **Consul**: Service discovery and configuration management
- **Registry**: Local Docker container registry

### Applications
- **adapter_application**: Data processing and import service
- **frontend**: Web frontend for applications
- **portfolio-performance**: Financial portfolio management application
