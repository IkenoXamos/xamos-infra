# Global GKE Configuration

This configuration defines the cluster that will host the portfolio application as well as supporting services (DevOps, Monitoring, etc.)

## Resource Optimization

Since Compute resources can be expensive we are aiming for maximum resource utilization and the ability to scale down to zero.

We additionally leverage GCP Spot instances where possible to significantly reduce costs.

## Getting access to the cluster

We use the `gcloud` CLI to obtain credentials and authenticate with the created cluster.

First the `gke-gcloud-auth-plugin` must be installed via `gcloud components install gke-gcloud-auth-plugin`. Then we can use `gcloud container clusters get-credentials <cluster-name> --region=<zone>`.

## Ingress Controller

GKE normally comes built-in with [GKE Ingress Controller](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress), but it has a downside where it will allocate a Cloud Load Balancer per Ingress resource in the cluster.

Considering [their pricing](https://cloud.google.com/vpc/network-pricing#lb) of ~$18 per month at a baseline it would be much too expensive for each individual Ingress resource to have its own dedicated load balancer. Especially since each hobby project will likely have at least 1 Ingress resource.

The solution is to leverage [Ingress NGINX Controller](https://github.com/kubernetes/ingress-nginx). This allows us to use a shared Load Balancer across our Ingress resources. The _downside_ is that we lose out on the GCP-native methods for performing TLS termination. Instead of getting to use [Google Certificate Manager](https://cloud.google.com/certificate-manager/docs/overview), we must instead manage our TLS certificates directly inside the cluster.

This means we have to pay much closer attention to the security surrounding these certificates and ensure they are correctly rotated.