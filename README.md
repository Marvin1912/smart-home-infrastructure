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

## Kubernetes Deployment

This infrastructure also supports deployment on Kubernetes with comprehensive resource configurations for scalable and resilient application deployment.

### Kubernetes Resources

The `k8s/` directory contains all necessary Kubernetes manifest files for deploying the Java application:

#### Deployment (`k8s/Deployment.yaml`)
- **Purpose**: Manages the deployment of the Java application with 3 replicas
- **Image**: Uses the local Docker registry image `192.168.178.29:5000/k8s:latest`
- **Resources**: Configured with memory limits (512Mi request, 1Gi limit) and CPU limits (250m request, 500m limit)
- **Java Options**: JVM tuned with `-Xms512m -Xmx1024m` for optimal performance
- **Port**: Exposes application on port 8080

#### Service (`k8s/Service.yaml`)
- **Purpose**: Provides stable network access to the Java application pods
- **Type**: ClusterIP for internal cluster access
- **Port Mapping**: External port 7080 → Internal port 8080
- **Selector**: Routes traffic to pods labeled with `app: k8s-java-app`

#### IngressRoute (`k8s/IngressRoute.yaml`)
- **Purpose**: Configures external access routes using Traefik ingress controller
- **Routes**:
  - `prometheus.kube.test.com` → Prometheus (port 9090)
  - `grafana.kube.test.com` → Grafana (port 80)
  - `app.kube.test.com` → Java Application (port 7080)
- **Entry Point**: Configured for web traffic on standard HTTP port

#### ServiceMonitor (`k8s/ServiceMonitor.yaml`)
- **Purpose**: Enables Prometheus monitoring for the Java application
- **Metrics Endpoint**: Scrapes `/actuator/prometheus` endpoint for application metrics
- **Port**: Targets the `http-web` service port
- **Namespace**: Monitors resources in the `default` namespace
- **Label Selector**: Specifically monitors services with `app: k8s-java-app` label

### Kubernetes Architecture

The Kubernetes deployment provides:

- **High Availability**: 3 replicas ensure application availability
- **Resource Management**: Controlled CPU and memory allocation
- **Service Discovery**: Stable service endpoints for internal communication
- **External Access**: Traefik-based ingress for external traffic routing
- **Monitoring Integration**: Prometheus-based metrics collection and monitoring
- **Scalability**: Easy horizontal scaling through replica configuration

### Deployment Instructions

1. **Prerequisites**:
   - Kubernetes cluster with Traefik ingress controller
   - Prometheus stack installed (`kube-prometheus-stack`)
   - Access to the local Docker registry at `192.168.178.29:5000`

2. **Deploy the application**:
   ```bash
   kubectl apply -f k8s/
   ```

3. **Verify deployment**:
   ```bash
   kubectl get pods -l app=k8s-java-app
   kubectl get services
   kubectl get ingressroutes
   ```

4. **Access the application**:
   - Application: http://app.kube.test.com
   - Prometheus: http://prometheus.kube.test.com
   - Grafana: http://grafana.kube.test.com
