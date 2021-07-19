# quest Solution
## Screen shoats
    quest homepage - quest-homepage.png
    eks cluster - EKS-Cluster.png
    eks cluster details - EKS-Cluster-Details.png
    ALB TLS   - ALB-TLS.png
    ALB Target group -   ALB-TG.yaml
## Docker File
    quest/Dockerfile
## IAC Code
    ### Terraform
         quest-iac/aws.tf                        quest-iac/quest-eks-sg.tf               quest-iac/quest-node-sg.tf
         quest-iac/quest-eks-iam-role.tf         quest-iac/quest-eks-variables.tf        quest-iac/quest-vpc.tf
         quest-iac/quest-eks-node-iam-role.tf    quest-iac/quest-eks.tf                  quest-iac/vpc-variables.tf

    k8s deployment descriptors
         quest-iac/quest-deployment.yaml quest-iac/quest-ingress.yaml    quest-iac/quest-service.yaml
    ###CLI and Kubectl used
        (1) Set up kube config
            aws sts get-caller-identity
            aws eks --region  us-east-1   update-kubeconfig --name quest
        (2) Set up ALB ingress controller
            kubectl get namespaces
            helm repo add eks https://aws.github.io/eks-charts
            kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
            helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=quest
            kubectl get pods -n kube-system
        (3) Deploy quest app
            kubectl  create namespace quest
            kubectl get namespace
            kubectl apply -f quest-deployment.yaml -n quest
            kubectl apply -f quest-service.yaml -n quest
            kubectl get pods -n quest
            kubectl apply -f quest-ingress.yaml -n quest  