# EKS-ArgoCD-Traefik-Terraform
EKS-ArgoCD-Traefik-Terraform

## Requirements
This deployment requires certain prerequisites

 * kubectl [Major:"1", Minor:"24"]
 * terraform v1.2.5
 * AWS CLI V2

## [Optional] Conifgure AWS CLI
Get Access key and Secret Access key of user
```
$ aws configure
```
and add the details
If you are using EC2 then use IAM role with the required permissions.

## Instruction to run
After cloning run the following commands 
```
$ cd EKS-ArgoCD-Traefik-Terraform
$ terraform init
$ terraform apply --auto-approve
```

After complettion run the following command to configure kubectl. Enter your region
aws eks update-kubeconfig --region <REGION> --name eks-argocd

## Instruction to update Infrastructure

To update any configuration in for script
After update in terrafrom 

Run following command to check the changes
```
$ terraform plan
```
Run following command to perform the changes
```
$ terraform apply --auto-approve
```

## Instruction to get ArgoCD admin password
Run following command to get password. Enter your region
```
$ aws secretsmanager get-secret-value --secret-id argocd --region <REGION> 
```

## Instruction to open ArgoCD UI
Run following command in you local. Make sure you have already configured kubectl
```
$ kubectl port-forward svc/argo-cd-argocd-server 8080:443 -n argocd 
```
Open http://127.0.0.1:8080/

## Instruction to remove Infrastructure

To destroy the whole infrastructure run the following command

```
$ terrafrom destroy
```

## Future Improvements  

These are few recommecndation

  * Use advance configuration for managed node groups I.e custom IAM role , custom security groups etc 
  * Use custom configuration for application deployment using helm 
  * Create an ingress for ArgoCD or use ALB service to access it directly  

