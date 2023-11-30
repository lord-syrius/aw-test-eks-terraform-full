cluster_name            = "aw-eks-test-localstack"
iac_environment_tag     = "development"
name_prefix             = "aw-test"
main_network_block      = "10.0.0.0/16"
cluster_azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
subnet_prefix_extension = 4
zone_offset             = 8
eks_managed_node_groups = {
  default = {
    min_size = 1
    max_size = 5
    desired_size = 3
    instance_type = "t3.medium"
  }
}
autoscaling_average_cpu = 70
spot_termination_handler_chart_name      = "aws-node-termination-handler"
spot_termination_handler_chart_repo      = "https://aws.github.io/eks-charts"
spot_termination_handler_chart_version   = "0.21.0"
spot_termination_handler_chart_namespace = "kube-system"
dns_base_domain               = "eks.localhost.localstack.cloud"
ingress_gateway_name          = "aws-load-balancer-controller"
ingress_gateway_iam_role      = "load-balancer-controller"
ingress_gateway_chart_name    = "aws-load-balancer-controller"
ingress_gateway_chart_repo    = "https://aws.github.io/eks-charts"
ingress_gateway_chart_version = "1.6.2"
external_dns_iam_role      = "external-dns"
external_dns_chart_name    = "external-dns"
external_dns_chart_repo    = "https://kubernetes-sigs.github.io/external-dns/"
external_dns_chart_version = "1.9.0"

external_dns_values = {
  provider = "aws"
}
namespaces = ["namespace1", "namespace2"]
admin_users = ["admin1", "admin2"]
developer_users = ["developer1", "developer2"] 
