# profile::swapfile
class profile::swapfile (
  $swapfile      = '/mnt/swap.1',
  $swapfilesize  = $::memorysize,
  $add_mount     = true,
  $options       = 'defaults',
  $timeout       = 300
){
  $swapfilesize_mb = to_bytes($swapfilesize) / 1048576
  exec { "Create swap file ${swapfile}":
    creates => $swapfile,
    timeout => $timeout,
    command => "/bin/dd if=/dev/zero of=${swapfile} bs=1M count=${swapfilesize_mb}"
  }

  file { $swapfile:
    owner   => root,
    group   => root,
    mode    => '0600',
    require => Exec["Create swap file ${swapfile}"],
  }

  exec { "Attach swap file ${swapfile}":
    command => "/sbin/mkswap ${swapfile} && /sbin/swapon ${swapfile}",
    require => File[$swapfile],
    unless  => "/sbin/swapon -s | grep ${swapfile}",
  }

  if $add_mount {
    mount { $swapfile:
      ensure  => present,
      fstype  => swap,
      device  => $swapfile,
      options => $options,
      dump    => 0,
      pass    => 0,
      require => Exec["Attach swap file ${swapfile}"],
    }
  }
}
