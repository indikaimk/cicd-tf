# terraform {
#   required_providers {
#     digitalocean = {
#       source  = "digitalocean/digitalocean"
#       version = ">= 2.41.0"
#     }
#     kubernetes = {
#       source = "hashicorp/kubernetes"
#       version = ">= 2.7.0"
#     }
#     helm = {
#       source  = "hashicorp/helm"
#       version = ">= 2.0.1"
#     }
#   }
# }

data "digitalocean_kubernetes_cluster" "primary" {
  name = var.cluster_name
}

resource "local_file" "kubeconfig" {
  depends_on = [var.cluster_id]
  count      = var.write_kubeconfig ? 1 : 0
  content    = data.digitalocean_kubernetes_cluster.primary.kube_config[0].raw_config
  filename   = "${path.root}/kubeconfig"
}

provider "kubernetes" {
  host             = data.digitalocean_kubernetes_cluster.primary.endpoint
  token            = data.digitalocean_kubernetes_cluster.primary.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = data.digitalocean_kubernetes_cluster.primary.endpoint
    token = data.digitalocean_kubernetes_cluster.primary.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "helm_release" "argocd" {
 name       = "argocd"
 repository = "https://argoproj.github.io/argo-helm"
 chart      = "argo-cd"
 version    = "7.5.2"

 namespace = "argocd"

 create_namespace = true

 set {
   name  = "server.service.type"
   value = "LoadBalancer"
 }
}

