# Global GKE Configuration

This configuration defines the cluster that will host the portfolio application as well as supporting services (DevOps, Monitoring, etc.)

## Resource Optimization

Since Compute resources can be expensive we are aiming for maximum resource utilization and the ability to scale down to zero.

We additionally leverage GCP Spot instances where possible to significantly reduce costs.