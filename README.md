#Localstack

Localstack nous permet de simuler des environnements typiques d'un fournisseur de cloud via Docker (AWS-EKS via Terraform dans notre cas) en gagnant en termes de rapidité de test et de formation sur les différents services AWS.
Installation de Localstack

Pour commencer, installons Localstack selon le système d'exploitation:
https://docs.localstack.cloud/getting-started/installation/

#Configuration de l'environnement

Il faut ensuite configurer les paquetages et commandes nécessaires (tflocal et awslocal) en se souvenant d'installer Terraform et de configurer correctement AWS CLI en amont. Il faut également s'assurer que Docker est correctement installé et a les droits nécessaires pour lancer les commandes Docker typiques.

https://github.com/localstack/terraform-local

```pip install terraform-local```

https://github.com/localstack/awscli-local

```pip install awscli-local```

Et configurer des alias et liens symboliques pour pouvoir disposer de ces commandes via le tab.

Une fois cela fait, il faut exporter les variables suivantes :

```export LOCALSTACK_AUTH_TOKEN="<TOKEN_ID>"```

pour pouvoir utiliser Localstack en version Pro (nécessaire pour EKS).
Puis exporter le profil nécessaire pour appeler (même de façon simulée) les ressources créées. En effet, du point de vue IAM, le profil communiquera réellement avec les différents rôles assumés, SCP compris, et cette instruction sera donc nécessaire même à l'intérieur de Docker.

```export AWS_PROFILE="aw-test"```

#Exécution de Localstack

À ce stade, clonons le dépôt Localstack, lançons docker-compose up -d pour créer le conteneur en version Pro et surveillons les logs avec localstack logs -f.

#Création de l'infrastructure
- cloner le repository
- cd localstack
- lancer un docker-compose up -d pour créer le conteneur en version pro (vérifier via docker ps)
docker ps
CONTAINER ID   IMAGE                       COMMAND                  CREATED          STATUS                            PORTS                                                                                                                                                                  NAMES
77689641dcbe   localstack/localstack-pro   "docker-entrypoint.sh"   12 seconds ago   Up 9 seconds (health: starting)   127.0.0.1:53->53/tcp, 127.0.0.1:443->443/tcp, 127.0.0.1:4510-4559->4510-4559/tcp, 127.0.0.1:4566->4566/tcp, 127.0.0.1:8080->8080/tcp, 127.0.0.1:53->53/udp, 5678/tcp   localstack-main



localstack logs -f 




LocalStack version: 3.0.0
LocalStack Docker container id: 77689641dcbe
LocalStack build date: 2023-11-16
LocalStack build git hash: 6dd3f3d

2023-11-29T15:32:55.161  INFO --- [  MainThread] l.bootstrap.licensingv2    : Successfully activated cached license xxxxxxxxxxxxxxxxxxxxxx:trial from /var/lib/localstack/cache/license.json 🔑✅
2023-11-29T15:32:57.929  INFO --- [  MainThread] l.extensions.platform      : loaded 0 extensions
2023-11-29T15:32:57.943  INFO --- [  MainThread] botocore.credentials       : Found credentials in environment variables.
2023-11-29T15:32:57.961  INFO --- [-functhread4] hypercorn.error            : Running on https://0.0.0.0:4566 (CTRL + C to quit)
2023-11-29T15:32:57.961  INFO --- [-functhread4] hypercorn.error            : Running on https://0.0.0.0:4566 (CTRL + C to quit)
2023-11-29T15:32:57.961  INFO --- [-functhread4] hypercorn.error            : Running on https://0.0.0.0:443 (CTRL + C to quit)
2023-11-29T15:32:57.961  INFO --- [-functhread4] hypercorn.error            : Running on https://0.0.0.0:443 (CTRL + C to quit)



- tflocal init 


tflocal plan \                                                             
  -var-file=base-network-development.tfvars \
  -var-file=base-eks-development.tfvars \
  -var-file=config-eks-development.tfvars \
  -var-file=config-iam-development.tfvars \
  -var-file=config-ingress-development.tfvars \
  -var-file=config-external-dns-development.tfvars \
  -var-file=config-namespaces-development.tfvars


tflocal apply \                                                             
  -var-file=base-network-development.tfvars \
  -var-file=base-eks-development.tfvars \
  -var-file=config-eks-development.tfvars \
  -var-file=config-iam-development.tfvars \
  -var-file=config-ingress-development.tfvars \
  -var-file=config-external-dns-development.tfvars \
  -var-file=config-namespaces-development.tfvars

##Interaction avec les services

CONTAINER ID   IMAGE                            COMMAND                  CREATED              STATUS                   PORTS                                                                                                                                                                  NAMES
640608d06ed8   ghcr.io/k3d-io/k3d-proxy:5.6.0   "/bin/sh -c nginx-pr…"   About a minute ago   Up About a minute        0.0.0.0:6443->6443/tcp, 0.0.0.0:8081->80/tcp                                                                                                                           k3d-aw-eks-test-localstack-serverlb
7fc9d9c540e6   rancher/k3s:v1.22.6-k3s1         "/bin/k3d-entrypoint…"   About a minute ago   Up About a minute                                                                                                                                                                               k3d-aw-eks-test-localstack-server-0
77689641dcbe   localstack/localstack-pro        "docker-entrypoint.sh"   4 minutes ago        Up 4 minutes (healthy)   127.0.0.1:53->53/tcp, 127.0.0.1:443->443/tcp, 127.0.0.1:4510-4559->4510-4559/tcp, 127.0.0.1:4566->4566/tcp, 127.0.0.1:8080->8080/tcp, 127.0.0.1:53->53/udp, 5678/tcp   localstack-main



docker exec -it 7fc9d9c540e6  /bin/sh
/ # kubectl get pods -A
NAMESPACE     NAME                                            READY   STATUS      RESTARTS   AGE
kube-system   local-path-provisioner-84bb864455-tgvjf         1/1     Running     0          2m41s
kube-system   helm-install-traefik-crd--1-lh2jl               0/1     Completed   0          2m42s
kube-system   helm-install-traefik--1-czhjl                   0/1     Completed   1          2m42s
kube-system   svclb-traefik-lphg9                             2/2     Running     0          2m7s
kube-system   metrics-server-ff9dbcb6c-pd92c                  1/1     Running     0          2m41s
kube-system   traefik-55fdc6d984-gwlvr                        1/1     Running     0          2m7s
kube-system   coredns-68f94966b4-2m2wz                        1/1     Running     0          98s
kube-system   aws-node-termination-handler-nc66q              1/1     Running     0          86s
kube-system   aws-load-balancer-controller-855f7b94c9-rdhl4   1/1     Running     0          84s
kube-system   aws-load-balancer-controller-855f7b94c9-dmpxc   1/1     Running     0          84s
kube-system   external-dns-5c78d5f7c5-v6lbm                   1/1     Running     0          86s
kube-system   aws-node-termination-handler-6zrfn              1/1     Running     0          53s
kube-system   svclb-traefik-q49jp                             2/2     Running     0          43s



 awslocal eks list-clusters
{
    "clusters": [
        "aw-eks-test-localstack"
    ]
}


awslocal eks list-nodegroups --cluster-name aw-eks-test-localstack                 
{
    "nodegroups": [
        "my-app-eks-x86-20231129153806701200000015"
    ]
}

