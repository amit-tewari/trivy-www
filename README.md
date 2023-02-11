# trivy-www
List vulnaribilities reported by Trivy operator

This application hourly generates HTML report of image vulnaribilities found by Trivy Operator running in cluster.
Reports are saved on a persistent volume in csv and json format, with a summary HTML page for navigation.

http://scans.example.com/reports is the path where reports should be accessible.


# Needs
Trivy operator to be deployed, and properly configured, in cluster before using this application.
Helm based operator installation instructions are available at https://github.com/aquasecurity/trivy-operator/tree/main/deploy/helm

- Ingress need to be enabled and properly configured
- Optionally: create a basic auth secret to protect reports

# TODO
- make kubectl version dynamic
- make regeneration period dynamic
- save summary in SQLite DB for trend analysis
