# Requirements
- terraform
- kubectl (if using pod subnets)

# Configuration
Example configuration provided in main.tf with variables in terraform.tfvars.
Variables & default values are described in modules README.

## Application access to AWS resources
To grant pod access to AWS resources IRSA is used (IAM roles for service accounts).
To create IAM role there is variable named `app_roles` which contains IAM role permissions.

With following example we're creating IAM role with full access to s3 buckets for service account `app` in default namespace.
```
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
```
Role arn returned by terraform (check app_role_arns output) should be added to the service account annotations used in configuration  
```
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::xxxxx:role/role-<cluster-name>-hello
  name: app
  namespace: default
```