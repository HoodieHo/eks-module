variable "cluster_name" {
  description = "Name of the EKS cluster. Also used as a prefix in names of related resources."
  type        = string
}

variable "cluster_enabled_log_types" {
  default     = []
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
}

variable "cluster_log_retention_in_days" {
  default     = 90
  description = "Number of days to retain log events. Default retention - 90 days."
  type        = number
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = null
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  type        = bool
  default     = false
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from."
  type        = string
  default     = "10.80.0.0/16"
}

variable "subnets" {
  description = "A list of subnets to place the EKS cluster and workers within."
  type        = list(string)
}

variable "cluster_create_timeout" {
  description = "Timeout value when creating the EKS cluster."
  type        = string
  default     = "30m"
}

variable "cluster_delete_timeout" {
  description = "Timeout value when deleting the EKS cluster."
  type        = string
  default     = "30m"
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC where the cluster and workers will be deployed."
  type        = string
}

variable "iam_path" {
  description = "If provided, all IAM roles will be created on this path."
  type        = string
  default     = "/"
}

variable "node_groups" {
  type        = any
  description = "List of node group parameters, a node group will be created for each object"
  default     = []
  # example
  # [
  #   {
  #     name                 = ""
  #     instance_type        = ""
  #     subnets              = []
  #     asg_desired_capacity = 1
  #     asg_max_size         = 1
  #     asg_min_size         = 1
  #     root_volume_type = gp2
  #     root_volume_size = 10
  #     root_iops = 0
  #     additional_security_group_ids = []
  #     tags = {}
  #     ami_id = ""
  #     key_name = ""
  #     ebs_optimized = false
  #     enable_monitoring = false
  #   }
  # ]
}

variable "enable_cluster_autoscaler" {
  type        = bool
  description = "Set true to allow Kubernetes Cluster Auto Scaler to scale the node group"
  default     = true
}

variable "map_roles" {
  type        = list(any)
  description = "Map of roles with required permissions"
  default     = []
}

variable "wait_for_cluster_cmd" {
  description = "Custom local-exec command to execute for determining if the eks cluster is healthy. Cluster endpoint will be available as an environment variable called ENDPOINT"
  type        = string
  default     = "for i in `seq 1 60`; do wget --no-check-certificate -O - -q $ENDPOINT/healthz >/dev/null && exit 0 || true; sleep 10; done; echo TIMEOUT && exit 1"
}

variable "wait_for_cluster_interpreter" {
  description = "Custom local-exec command line interpreter for the command to determining if the eks cluster is healthy."
  type        = list(string)
  default     = ["/bin/sh", "-c"]
}

variable "kms_arn" {
  type        = string
  description = "Amazon Resource Name (ARN) of the Key Management Service (KMS) customer master key (CMK)"
  default     = ""
}

variable "metrics_server_chart_version" {
  type        = string
  description = "Metrics server chart version"
  default     = "3.8.4"
}

variable "private_endpoint_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12"]
  description = "List of default cidrs allowed to access cluster resources"
}

variable "alb_allowed_cidrs" {
  type        = list(string)
  default     = []
  description = "List of cidrs allowed to access alb. If empty private_endpoint_cidrs is used"
}

variable "private_endpoint_sgs" {
  type        = list(string)
  default     = []
  description = "List of security groups allowed to access private endpoint"
}

variable "block_metadata" {
  type        = bool
  default     = true
  description = "Block http://169.254.169.254 for pods - use service accounts"
}

variable "pod_subnets" {
  type        = list(string)
  default     = []
  description = "List of additional subnets to host eks pods"
  validation {
    condition     = length(var.pod_subnets) >= 2 || length(var.pod_subnets) == 0
    error_message = "The pod_subnets value must contain at least 2 subnets."
  }
}

variable "deploy_alb_ingress" {
  type        = bool
  default     = true
  description = "Deploy alb ingress controller"
}

variable "create_default_ingress" {
  type        = bool
  default     = true
  description = "Create default ingress resource"
}
variable "alb_custom_attrs" {
  type        = map(string)
  default     = {}
  description = "ALB custom attributes configuration"
}

variable "alb_ingress_chart_version" {
  type        = string
  default     = "1.4.7"
  description = "Chart version for alb ingress controller"
}

variable "autoscaler_version" {
  type        = string
  description = "Cluster autoscaler chart version"
  default     = "9.25.0"
}

variable "metrics_server_settings" {
  type        = map(string)
  description = "Metrics server configuration"
  default = {
    "containerPort"     = "8443"
    "apiService.create" = "true"
  }
}

variable "addon_configs" {
  type        = map(string)
  description = <<EOD
  Additional configuration for EKS Addons. Check addon schema to verify available options.
  e.g.
  {
    vpc-cni = {
      nodeSelector = {
        app = example
      }
    }
  }
EOD
  default     = {}
}

variable "addon_versions" {
  type        = map(string)
  description = "Addon versions mapping. Latest used if none provided"
  default     = {}
}

variable "app_roles" {
  type        = map(any)
  description = <<EOD
  Application roles for pods to use.
  Example:
  app_roles = {
    hello = {
      permissions = [
        {
          actions = ["s3:*"]
          resources = ["*"]
        }
      ]
      namespace = default
      serviceaccount = app
    }
  }
EOD
}
