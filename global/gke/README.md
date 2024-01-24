# Global GKE Configuration

This configuration defines the cluster that will host the portfolio application as well as supporting services (DevOps, Monitoring, etc.)

## Resource Optimization

Since Compute resources can be expensive we are aiming for maximum resource utilization and the ability to scale down to zero.

We additionally leverage GCP Spot instances where possible to significantly reduce costs.

## Getting access to the cluster

We use the `gcloud` CLI to obtain credentials and authenticate with the created cluster.

First the `gke-gcloud-auth-plugin` must be installed via `gcloud components install gke-gcloud-auth-plugin`. Then we can use `gcloud container clusters get-credentials <cluster-name> --region=<zone>`.