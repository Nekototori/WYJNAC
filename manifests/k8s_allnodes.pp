# This is settings that applies to all nodes.

# Locked the k8s to a specific version in case this is spun up later or
# someone wanted to scale up (or upgrade via YOLO but didn't test that)
# We could consider pinning it to a major and/or minor version, but I've
# had patch versions break stuff, so hardcode is safest.

class k8s_allnodes {

$version = '1.35.0-1.1'

#Note, I'm using exec here to reduce dependency on modules.
# There's better ways to do this (more performant) but the below approach
# greatly reduces Puppet bootstrap requirements, and complexity.

# Also, we need path, so this is set as a default.
Exec { path => '/bin/:/sbin/:/usr/bin/:/usr/sbin/' }


# These things are in the k8s docs, but voodoo doodoo a bit.
exec { "swap off":
  command => "swapoff -a",
  unless => "grep partition /proc/swaps"
}

exec { 'load overlay module':
  command   => 'modprobe overlay',
  unless    => 'lsmod | grep overlay',
}

exec { 'load netfilter module':
  command   => 'modprobe br_netfilter',
  unless    => 'lsmod | grep br_netfilter',
}

file { '/etc/sysctl.d/10-kubernetes.conf':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\n",
  require => [Exec['load overlay module'], Exec['load netfilter module']],
  notify  => Exec['apply sysctl k8s']
}


# I hate this. So many better ways by just including stdlib or something...
exec { 'apply sysctl k8s':
  command => '/sbin/sysctl --system',
  unless  => 'sysctl net.bridge.bridge-nf-call-iptables | grep -q "1" && \
              sysctl net.bridge.bridge-nf-call-ip6tables | grep -q "1" && \
              sysctl net.ipv4.ip_forward | grep -q "1"',
}

# Not my ideal idempotent, blah blah, should fix.
exec { 'k8s-gpg-key':
  command => 'curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg',
  creates => '/etc/apt/keyrings/kubernetes-archive-keyring.gpg',
}

file { '/etc/apt/sources.list.d/kubernetes.list':
  ensure  => file,
  content => 'deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /',
  require => Exec['k8s-gpg-key'],
}

exec { 'apt-update':
  command     => '/usr/bin/apt-get update',
  refreshonly => true,
  subscribe   => File['/etc/apt/sources.list.d/kubernetes.list'],
}

package { 'containerd':
  ensure => installed,
  require => [Exec['k8s-gpg-key'],File['/etc/apt/sources.list.d/kubernetes.list'],Exec['apt-update']]
}

# I broke this out just for version locking.
package { ['kubelet','kubeadm','kubectl']:
  ensure => $version,
  require => Exec['apt-update']
}

# Whee config. If this fails, we got no fallback right now. Cattle it if this is the problem.
exec { 'containerd-config':
  command => '/bin/bash -c "mkdir -p /etc/containerd && containerd config default > /etc/containerd/config.toml"',
  creates => '/etc/containerd/config.toml',
}

# There's some fallback warning, so addressing it this way.
exec { 'containerd-systemd-cgroup':
  command => '/bin/sed -i \'s/SystemdCgroup = false/SystemdCgroup = true/\' /etc/containerd/config.toml',
  onlyif  => '/bin/grep -q \'SystemdCgroup = false\' /etc/containerd/config.toml',
  notify  => Service['containerd'],
}


service { 'containerd':
  ensure    => running,
  enable    => true,
  require   => Package['containerd'],
}

}

include k8s_allnodes
