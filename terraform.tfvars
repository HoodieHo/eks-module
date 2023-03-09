cluster_name = "test-eks-cluster"
vpc_id = "vpc-xxxxx"
subnets = [
        "subnet-xxx",
        "subnet-xxx"
    ]
node_groups = [
      {
        name               = "main-0"
        instance_type      = "m5.large"
        asg_max_size       = 5
        asg_min_size       = 1
        root_volume_size   = 20
        subnet             = "subnet-xxx"
        kubelet_extra_args = "--image-gc-low-threshold=50 --image-gc-high-threshold=70"
      },
      {
        name               = "main-1"
        instance_type      = "m5.large"
        asg_max_size       = 5
        asg_min_size       = 1
        root_volume_size   = 20
        subnet             = "subnet-xxx"
        kubelet_extra_args = "--image-gc-low-threshold=50 --image-gc-high-threshold=70"
      },
    ]
app_roles = {
        hello = {
            permissions = [
                {
                actions = ["s3:*"]
                resources = ["*"]
                }
            ]
            namespace = "default"
            serviceaccount = "app"
        }
    }
tags = {
        "environment" = "poc"
    }
