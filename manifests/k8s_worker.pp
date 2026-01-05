Exec { path => '/bin/:/sbin/:/usr/bin/:/usr/sbin/' }


exec { 'kubeadm-join':
  command => '/vagrant/join_command.sh --cri-socket=unix:///run/containerd/containerd.sock',
  creates => '/etc/kubernetes/kubelet.conf',
}
