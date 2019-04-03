#!/bin/bash
yum install -y vim
cat <<EOF >> /etc/hosts
10.0.15.21       kube01
10.0.15.22       kube02
10.0.15.10       master
EOF
setenforce 0
sed -i 's?SELINUX=.*?SELINUX=permissive?' /etc/selinux/config
modprobe br_netfilter
swapoff -a
sed -i '/swap/d' /etc/fstab
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum clean all
yum install -y yum-utils device-mapper-persistent-data lvm2 docker-ce kubelet kubeadm kubectl
for service in docker kubelet; do
  systemctl enable $service
  systemctl start $service
done
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
systemctl restart docker
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
kubeadm join 192.168.9.13:6443 --token g45hbt.uh3irv6qst0facyi     --discovery-token-ca-cert-hash sha256:5c00c3f2bed0682959449cc5099cd62b39fd87c80faa45e4159857dd36dde685 
