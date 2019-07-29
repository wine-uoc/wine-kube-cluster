# wine-kube-cluster
our kubernetes cluster config

## Setup RPIs
I am following this guide to setup Raspberry Pis 3b+. 

https://medium.com/nycdev/k8s-on-pi-9cc14843d43

We are using Raspbian Buster version. 

This guide has been also useful 

https://evalle.xyz/posts/setting-up-a-kubernetes-1-14-raspberry-pi-cluster-using-kubeadm/

## Install docker in all RPIs
Even we are using buster, at the current moment buster version of docker is not available.

We need to install then the stretch version and avoid installing recommended apps such as autodks which causes docker to fail. 

```
sudo apt-get update
apt-get install apt-transport-https ca-certificates software-properties-common
curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -
echo "deb https://download.docker.com/linux/raspbian/ stretch stable" > /etc/apt/sources.list.d/docker.list
apt install --no-install-recommends docker-ce
sudo usermod pi -aG docker
```

get docker installed in all RPIs of your cluster. Master and all workers.

## Install Kubernetes

Install kubernetes in all RPIs (master and workers). Reboot afterwards.
```
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -q && sudo apt-get install -y kubeadm kubectl kubelet
sudo reboot
```

## Starting the cluster at the master node

run the following to start kubernetes
1. disable swap
```
sudo dphys-swapfile swapoff && sudo dphys-swapfile uninstall && sudo update-rc.d dphys-swapfile remove
```
2. pull kube images
```
sudo kubeadm config images pull -v3
```
3. init kubernetes. We are going to use Weave Net as network overlay.
```
sudo kubeadm init --token-ttl=0
```
this can take some time. When it finishes do:
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
keep the join token. You will need it for later in the worker nodes. 
```
sudo kubeadm join 192.168.0.100:6443 --token s1kgo7.ijqk65zrtfa4macs \
    --discovery-token-ca-cert-hash sha256:78244c8b15bd9be6bf164d41c1db1d7e189887af9db16485cbca2809ed3a9637
``` 
4. Create the network overlay
```
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```
and enable net filter on bridges.
```
sudo sysctl net.bridge.bridge-nf-call-iptables=1
```
make sure all is working
```
kubectl get all -A
```
5. If you want to run the dasboard, install it first before joining worker nodes to the cluster. We faced some problems when doing it when worker nodes have joined.

create a file named dashboard-adminuser.yaml with the folling content

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
```
Create the user
```
kubectl apply -f dashboard-adminuser.yaml
```

get the token. Keep it as it will be used to login into the dashboard.
```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
``` 
Install the dashboard. Follow this guide.

https://github.com/kubernetes/dashboard/releases/tag/v2.0.0-beta2

mainly execute this. Note we are using v2.00.-beta2. beta1 was causing some problems. 
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta2/aio/deploy/recommended.yaml
```
Once done, start the proxy
```
kubectl proxy --address 0.0.0.0 --accept-hosts '.*'&
```
Try accessing the dashboard
http://192.168.0.100:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/

use the token to authenticate.

## Joining the worker nodes 

Now that the master is running. We can join the nodes. Use your join credentials as obtained before. 
```
sudo kubeadm join 192.168.0.100:6443 --token my2gv0.qtza7gh5atenzx2b \
    --discovery-token-ca-cert-hash sha256:7dd8997ccb881358c4b384a3942d9a62ce2c719204e5b3dc0b50b4104a4f634a
```

check that everything is running properly at the master
```
kubectl get all -A
```

## Reseting the cluster, master and worker nodes. 

you can clear everything by executing the following at each node (master and worker nodes)
```
sudo kubeadm reset
```

## Unjoin a worker node

if you want to remove a node from the cluster in a safe manner do the following:

### In the master

```
kubectl get nodes
```

First drain the node

```
kubectl drain <node-name>
```

You might have to ignore daemonsets and local-data in the machine. In this case use:

```
kubectl drain <node-name> --ignore-daemonsets --delete-local-data
```

Finally delete the node

```
kubectl delete node <node-name>
```

### In the node.

Reset it.

```
sudo kubeadm reset
```

# Deploy an image hosted at docker hub

consider we have a yaml file specifying the deployment and pointing to the docker hub image. For example see 

https://github.com/wine-uoc/wine-kube-cluster/tree/master/sample-deployment/kubernetes

Deploy it from the master node as:

```
kubectl apply -f https://raw.githubusercontent.com/wine-uoc/wine-kube-cluster/master/sample-deployment/kubernetes/deployment.yaml
```

check all worked by 

```
kubectl get pods
```

