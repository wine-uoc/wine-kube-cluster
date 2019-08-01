#/bin/bash!

echo "installing docker"

apt-get update

apt-get install curl apt-transport-https ca-certificates software-properties-common

curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -

echo "deb https://download.docker.com/linux/raspbian/ stretch stable" > /etc/apt/sources.list.d/docker.list

apt install --no-install-recommends docker-ce

usermod pi -aG docker


echo "docker already installed!"


echo "installing kubernetes"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -q && apt-get install -y kubeadm kubectl kubelet

echo "Kubernetes already installed. Reboot now!"


