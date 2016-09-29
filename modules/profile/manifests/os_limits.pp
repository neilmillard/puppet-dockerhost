# class profile::os_limits (
class profile::os_limits (
    $sysctl_vm_max_map_count=0,
    $sysctl_net_core_somaxconn=128,
    $sysctl_net_ipv4_tcp_tw_recycle=0,
    $sysctl_net_ipv4_tcp_tw_reuse,
    $sysctl_net_core_netdev_max_backlog=0,
    $sysctl_net_core_rmem_max=0,
    $sysctl_net_core_wmem_max=0,
    $sysctl_net_core_rmem_default=0,
    $sysctl_net_core_wmem_default=0,
    $sysctl_net_ipv4_udp_mem='',
    $sysctl_net_core_optmem_max=0,
    $sysctl_net_ipv4_udp_rmem_min=0,
    $sysctl_net_netfilter_nf_conntrack_max=undef,
    $sysctl_vm_vfs_cache_pressure=undef,
    $sysctl_vm_overcommit_ratio=undef,
    $sysctl_vm_dirty_background_ratio=undef,
    $sysctl_vm_dirty_ratio=undef
  ) {

  # Remove the override file rhbz 432903 to ensure the limits.conf value is
  # picked up
  file { '/etc/security/limits.d/90-nproc.conf':
    ensure => 'absent',
  }

  if $sysctl_vm_max_map_count != 0 {
    sysctl { 'vm.max_map_count': value => $sysctl_vm_max_map_count }
  }

  if $sysctl_net_core_netdev_max_backlog != 0 {
    sysctl { 'net.core.netdev_max_backlog':
      value => $sysctl_net_core_netdev_max_backlog
    }
  }

  if $sysctl_net_core_rmem_max != 0 {
    sysctl { 'net.core.rmem_max': value => $sysctl_net_core_rmem_max }
  }

  if $sysctl_net_core_wmem_max != 0 {
    sysctl { 'net.core.wmem_max': value => $sysctl_net_core_wmem_max }
  }

  if $sysctl_net_core_rmem_default != 0 {
    sysctl { 'net.core.rmem_default': value => $sysctl_net_core_rmem_default }
  }

  if $sysctl_net_core_wmem_default != 0 {
    sysctl { 'net.core.wmem_default': value => $sysctl_net_core_wmem_default }
  }

  if $sysctl_net_core_optmem_max != 0 {
    sysctl { 'net.core.optmem.max': value => $sysctl_net_core_optmem_max }
  }

  if $sysctl_net_ipv4_udp_rmem_min != 0 {
    sysctl { 'net.ipv4.udp.rmem.min': value => $sysctl_net_ipv4_udp_rmem_min }
  }

  if $sysctl_net_ipv4_udp_mem != '' {
    sysctl { 'net.ipv4.udp_mem': value => $sysctl_net_ipv4_udp_mem }
  }

  if $sysctl_net_netfilter_nf_conntrack_max != undef {
    exec { 'insert_nf_conntrack':
      command => '/sbin/modprobe nf_conntrack'
    }->

    sysctl { 'net.netfilter.nf_conntrack_max':
      value   => $sysctl_net_netfilter_nf_conntrack_max,
    }
  }

  if $sysctl_vm_vfs_cache_pressure != undef {
    sysctl { 'vm.vfs_cache_pressure': value => $sysctl_vm_vfs_cache_pressure }
  }

  if $sysctl_vm_overcommit_ratio != undef {
    sysctl { 'vm.overcommit_ratio': value => $sysctl_vm_overcommit_ratio }
  }

  if $sysctl_vm_dirty_background_ratio != undef {
    sysctl { 'vm.dirty_background_ratio':
      value => $sysctl_vm_dirty_background_ratio
    }
  }

  if $sysctl_vm_dirty_ratio != undef {
    sysctl { 'vm.dirty_ratio': value => $sysctl_vm_dirty_ratio }
  }

  sysctl { 'net.core.somaxconn': value => $sysctl_net_core_somaxconn }
  sysctl { 'net.ipv4.tcp_tw_recycle': value => $sysctl_net_ipv4_tcp_tw_recycle }
  sysctl { 'net.ipv4.tcp_tw_reuse': value => $sysctl_net_ipv4_tcp_tw_reuse }
  include ::limits

}
