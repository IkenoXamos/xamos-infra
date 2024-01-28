# Create a DNS entry for the Load Balancer
# Following https://cert-manager.io/docs/tutorials/acme/nginx-ingress/#step-3---assign-a-dns-name

# Fetch the source zone
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone
data "aws_route53_zone" "source" {
  name         = "xamos.org"
  private_zone = false
}

# Fetch the IP address of the Load Balancer
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service
data "kubernetes_service" "ingress_controller" {
  metadata {
    name      = "ingress-ingress-nginx-controller"
    namespace = "ingress"
  }

  depends_on = [
    helm_release.ingress,
  ]
}

# Create a managed zone in GCP for the kuard subdomain
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone
resource "google_dns_managed_zone" "kuard" {
  name        = "kuard"
  dns_name    = "kuard.${data.aws_route53_zone.source.name}."
  description = "Kuard DNS zone"
  labels = {
    purpose = "demo"
  }
}

# Pass ownership of the subdomain to GCP by creating an NS record in AWS Route 53
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "kuard" {
  zone_id = data.aws_route53_zone.source.zone_id
  name    = "kuard.${data.aws_route53_zone.source.name}"
  type    = "NS"
  ttl     = 172800

  # The contents of the NS record must be the name servers from the managed zone from GCP
  records = google_dns_managed_zone.kuard.name_servers
}

# Assign the IP address of the Load Balancer to the subdomain
# This should redirect "kuard.xamos.org" to the Load Balancer"
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set
resource "google_dns_record_set" "kuard" {
  name = "kuard.${data.aws_route53_zone.source.name}."
  type = "A"
  ttl  = 300 # Keeping it short for demo purposes

  managed_zone = google_dns_managed_zone.kuard.name

  rrdatas = [
    data.kubernetes_service.ingress_controller.status.0.load_balancer.0.ingress.0.ip
  ]
}

# Create the actual demo application
# Following https://cert-manager.io/docs/tutorials/acme/nginx-ingress/#step-4---deploy-an-example-service
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment
resource "kubernetes_deployment" "kuard" {
  metadata {
    name = "kuard"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kuard"
      }
    }

    template {
      metadata {
        labels = {
          app = "kuard"
        }
      }

      spec {
        container {
          image = "gcr.io/kuar-demo/kuard-amd64:1"
          name  = "kuard"

          port {
            container_port = 8080
          }

          # The example does not include resource requests/limits or liveness probes
          # But it's a good habit to include them
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }

            initial_delay_seconds = 15
            period_seconds        = 30
          }
        }
      }
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service
resource "kubernetes_service" "kuard" {
  metadata {
    name = "kuard"
  }

  spec {
    selector = {
      app = "kuard"
    }

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
      name        = "http"
    }

    type = "ClusterIP"
  }
}

# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1
resource "kubernetes_ingress_v1" "kuard" {
  metadata {
    name = "kuard"
    annotations = {
      # "cert-manager.io/cluster-issuer" = "letsencrypt-staging"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["kuard.xamos.org"]
      secret_name = "kuard-tls"
    }

    rule {
      host = "kuard.xamos.org"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "kuard"
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    google_dns_record_set.kuard,
  ]
}
