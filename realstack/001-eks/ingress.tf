# create some variables
variable "dns_base_domain" {
  type        = string
  description = "DNS Zone name to be used from EKS Ingress."
}
variable "ingress_gateway_name" {
  type        = string
  description = "Load-balancer service name."
}
variable "ingress_gateway_iam_role" {
  type        = string
  description = "IAM Role Name associated with load-balancer service."
}
variable "ingress_gateway_chart_name" {
  type        = string
  description = "Ingress Gateway Helm chart name."
}
variable "ingress_gateway_chart_repo" {
  type        = string
  description = "Ingress Gateway Helm repository name."
}
variable "ingress_gateway_chart_version" {
  type        = string
  description = "Ingress Gateway Helm chart version."
}

# get (externally configured) DNS Zone
# ATTENTION: if you don't have a Route53 Zone already, replace this data by a new resource
#data "aws_route53_zone" "base_domain" {
  #name = var.dns_base_domain
#}

resource "aws_route53_zone" "base_domain" {
  name = var.dns_base_domain
}

# create AWS-issued SSL certificate
resource "aws_acm_certificate" "eks_domain_cert" {
  domain_name               = var.dns_base_domain
  subject_alternative_names = ["*.${var.dns_base_domain}"]
  validation_method         = "DNS"

  tags = {
    Name = "${var.dns_base_domain}"
  }
}
resource "aws_route53_record" "eks_domain_cert_validation_dns" {
  for_each = {
    for dvo in aws_acm_certificate.eks_domain_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  #zone_id         = data.aws_route53_zone.base_domain.zone_id
  zone_id         = aws_route53_zone.base_domain.zone_id
}
resource "aws_acm_certificate_validation" "eks_domain_cert_validation" {
  certificate_arn         = aws_acm_certificate.eks_domain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.eks_domain_cert_validation_dns : record.fqdn]
}

# deploy Ingress Controller
resource "kubernetes_service_account" "load_balancer_controller" {
  metadata {
    name      = var.ingress_gateway_name
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = var.ingress_gateway_name
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.ingress_gateway_iam_role}"
    }
  }
}
resource "kubernetes_secret" "load_balancer_controller" {
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true

  metadata {
    namespace     = kubernetes_service_account.load_balancer_controller.metadata.0.namespace
    generate_name = "${kubernetes_service_account.load_balancer_controller.metadata.0.name}-token"
    annotations   = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.load_balancer_controller.metadata.0.name
    }
  }
}


resource "helm_release" "ingress_gateway" {
  name       = var.ingress_gateway_chart_name
  chart      = var.ingress_gateway_chart_name
  repository = var.ingress_gateway_chart_repo
  version    = var.ingress_gateway_chart_version
  namespace  = "kube-system"

  values = [
    templatefile(
      "${path.module}/templates/alb_controller_values.yaml",
      {
        aws_region                     = "us-east-1",
        eks_cluster_id                 = var.cluster_name,
        aws_iam_role_lb_controller_arn = "${var.ingress_gateway_iam_role}"
      }
    )
  ]



  set {
     name  = "vpcId"
     value = ""
 }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
     name  = "region"
     value = "us-east-1"
 }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.load_balancer_controller.metadata.0.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }
#  set {
#     name = "image.repository"
#     value = format("602401143452.dkr.ecr.eu-west-2.amazonaws.com/amazon/aws-load-balancer-controller")
#  }
}

##################### SAMPLE APP CREATION

#resource "kubernetes_service" "hello-kubernetes" {
#  metadata {
#    name      = "hello-kubernetes"
#    namespace = "default"
#  }
#  spec {
#    selector = {
#      app = "hello-kubernetes"
#    }
#    port {
#      port        = 8080
#      target_port = 8080
#    }
#  }
#}
#
#resource "aws_alb_target_group" "example" {
#  name     = "example"
#  port     = 8080
#  protocol = "HTTP"
#  vpc_id   = ""
#
#  deregistration_delay = 10
#
#  health_check {
#    enabled = true
#    path = "/health"
#  }
#
#  tags = {
#    Name = "example"
#  }
#}
#
#resource "aws_route53_record" "example" {
#  zone_id = aws_route53_zone.base_domain.zone_id
#  name    = "eks.syrius.me"
#  type    = "A"
#  
#
#  alias {
#    name                   = var.dns_base_domain
#    zone_id                = aws_route53_zone.base_domain.zone_id
#    evaluate_target_health = true
#  }
#} 
#
#resource "kubernetes_ingress" "example" {
#  metadata {
#    name      = "example-ingress"
#    namespace = "default"
#
#    annotations = {
#      "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
#      "alb.ingress.kubernetes.io/target-type"        = "ip"
#      "alb.ingress.kubernetes.io/load-balancer-name" = "my-app-eks"
#      "kubernetes.io/ingress.class"                  = "alb"
#      "external-dns.alpha.kubernetes.io/hostname"  =  "eks.syrius.me"
#      "external-dns.alpha.kubernetes.io/alias" =      "true"
#    }
#  }
#
#  spec {
#
#    rule {
#      host = "eks.syrius.me"
#      http {
#        path {
#          path = "/"
#          backend {
#            service_name = "hello-kubernetes"
#            service_port = 8080
#          }
#        }
#      }
#    }
#  }
#}
