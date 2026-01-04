# k8s_controlplane.pp
# Applies only to the control-plane node

#We are trusting that the allnodes.pp manifest actually loaded and was successful.
# I did not find error handling and try/catch equivalents within vagrant I'd consider passable today.

# Creating the kubeadm config raw to make sure all the settings are there. Had some issues with the flags playing nice.
$kubeadm_config = @(END)
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v1.35.0
controlPlaneEndpoint: "192.168.69.10:6443"
networking:
  serviceSubnet: "10.96.0.0/12"
  podSubnet: "192.168.0.0/16"
  dnsDomain: "cluster.local"
controllerManager:
  extraArgs:
    "node-cidr-mask-size": "24"
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
serverTLSBootstrap: true
END

$user_kubeconfig = @(END)
CLUSTER_SERVER=$(/usr/bin/kubectl config view --kubeconfig=/vagrant/kubeconfig -o jsonpath='{.clusters[0].cluster.server}')
/usr/bin/kubectl config set-cluster kubernetes --server=$CLUSTER_SERVER --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --kubeconfig=user.kubeconfig
END

Exec { path => '/bin/:/sbin/:/usr/bin/:/usr/sbin/' }

file {'/home/vagrant/kubeadm-config.yaml':
  ensure  => file,
  owner   => 'vagrant',
  group   => 'vagrant',
  mode    => '0700',
  content => $kubeadm_config,
}

exec { 'kubeadm-init':
  command => '/usr/bin/kubeadm init --config /home/vagrant/kubeadm-config.yaml',
  creates => '/etc/kubernetes/admin.conf',
  require => File['/home/vagrant/kubeadm-config.yaml'],
}

# Setup kubeconfig for vagrant user
file { '/home/vagrant/.kube':
  ensure  => directory,
  owner   => 'vagrant',
  group   => 'vagrant',
  mode    => '0700',
  require => Exec['kubeadm-init'],
}

file { '/home/vagrant/.kube/config':
  ensure  => file,
  owner   => 'vagrant',
  group   => 'vagrant',
  mode    => '0600',
  source  => '/etc/kubernetes/admin.conf',
  require => File['/home/vagrant/.kube'],
}

# We then copy the kubeadm configuration file to the shared directory so commands can be ran on the "jumpbox"

file { '/vagrant/kubeconfig':
  ensure  => file,
  owner   => 'vagrant',
  group   => 'vagrant',
  mode    => '0600',
  source  => '/home/vagrant/.kube/config', 
  require => File['/home/vagrant/.kube/config'],
}

# Lastly, we pre-seed the skeleton of the config. Setup steps cover adding their own cert to it so they can auth.

file { '/vagrant/config_gen.sh':
  ensure   => file,
  owner    => 'vagrant',
  group    => 'vagrant',
  mode     => '0755',
  content  => $user_kubeconfig, 
  require  => File['/vagrant/kubeconfig'],
}

exec {'create user kubeconfig':
  command => '/vagrant/config_gen.sh',
  creates => '/vagrant/user.kubeconfig',
  require => File['/vagrant/config_gen.sh']
}

# F Calico
# This looks sketch, but weave is apparently in a sad state also, see: https://rajch.github.io/weave/ and "do your research"
exec { 'apply weave':
  command => 'kubectl apply -f https://reweave.azurewebsites.net/k8s/v1.35/net.yaml',
  unless  => 'kubectl get pods -n kube-system | grep weave',
  require => File['/home/vagrant/.kube/config'],
}





# Installing Calico per: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart
#exec { 'apply-tigera-operator':
#  command => 'kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/tigera-operator.yaml',
#  path    => ['/bin','/usr/bin'],
#  unless  => 'kubectl get pods -n kube-system | grep calico',
#  require => File['/home/vagrant/.kube/config'],
#}
# Apply Calico CNI after a short sleep. These VMs need tiiiime.

#exec { 'apply-calico':
#  command => 'sleep 30 && kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/custom-resources.yaml',
#  path    => ['/bin','/usr/bin'],
#  unless  => 'kubectl get pods -n kube-system | grep calico',
#  require => Exec['apply-tigera-operator'],
#}

# 4. Export join command to shared folder for workers
exec { 'export-join-command':
  command => 'kubeadm token create --print-join-command > /vagrant/join_command.sh',
  creates => '/vagrant/join_command.sh',
  require => Exec['kubeadm-init'],
}
