#!/bin/bash
set -e
set -x

useradd kube
mkdir /home/kube/.ssh/
cp /vagrant/id_rsa /home/kube/.ssh/
cat /vagrant/id_rsa.pub > /home/kube/.ssh/authorized_keys
chmod 600 /home/kube/.ssh/id_rsa
chown -R kube:kube /home/kube/
yum install -y vim

ip=$(ip a  | grep 'eth1$' | awk '{print $2}' | sed 's?/.*??g')

setenforce 0
sed -i 's?SELINUX=.*?SELINUX=permissive?' /etc/selinux/config

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
yum install -y vim yum-utils device-mapper-persistent-data lvm2 docker-ce kubelet kubeadm kubectl

echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=${ip}\"" >> /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload

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

echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
echo "@reboot echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables" >> /var/spool/cron/root

systemctl restart docker
if hostname | grep -q master; then
  kubeadm init --apiserver-advertise-address=${ip} --pod-network-cidr=10.244.0.0/16 | grep -A1 '^kubeadm join' > /tmp/join_command
  mkdir -p ~/.kube
  cp /etc/kubernetes/admin.conf ~/.kube/config
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
  kubectl create deployment botpress --image=index.docker.io/honzat/kubebot:v11_7_4
  kubectl patch deployment  botpress -p '{"spec":{"template":{"spec":{"containers":[{"name":"kubebot","env":[{"name":"DATABASE","value":"postgres"},{"name":"DATABASE_URL","value":"postgres://botpress:botpass@207.154.207.148:5432/botpress"}]}]}}}}'
  kubectl create service nodeport botpress --tcp=3000
  kubectl patch svc botpress -p '{"spec": {"sessionAffinity": "ClientIP"}}'
  kubectl patch svc botpress -p '{"spec": {"ports": [{"port": 3000,"nodePort": 31227,"name": "3000"}]}}'
  kubectl scale --replicas=2 deployment/botpress
else
  sudo -u kube scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null master:/tmp/join_command /tmp
  bash /tmp/join_command
fi
