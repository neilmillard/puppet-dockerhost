# profile::docker_base
class profile::docker_base(
  $registry = 'registry.com:5000',
  $docker_home = '/var/lib/docker',
  $docker_rpm = hiera('profile::docker_base::docker_rpm', 'https://s3-eu-west-1.amazonaws.com/static.millardtechnicalservices.co.uk/docker/docker-io-1.7.1-4.el6.x86_64.rpm'),
  $extra_parameters = "`grep nameserver /etc/resolv.conf | \
    grep -v '.0.2'| sed 's/nameserver/--dns/g' | tr '\n' ' '`",
  $extra_parameters = generate('/bin/bash', '-c', 'PATH=$PATH:~/bin:~/usr/bin grep nameserver /etc/resolv.conf|grep -v \'.0.2\'| sed \'s/nameserver/--dns/g\' | tr \'\n\' \' \' '),
  $log_rotate = false,
  $direct_lvm_mode = false,
  $volume = '/dev/xvdb'
){

  file { $docker_home:
    ensure => directory,
  }

  if $log_rotate {
    file { '/etc/logrotate.d/docker-containers':
      ensure => present,
      owner  => root,
      group  => root,
      mode   => '0664',
      source => 'puppet:///modules/profile/logrotate/docker-containers'
    }
  }
  if $direct_lvm_mode == true or $direct_lvm_mode == 'true'{

    $storage_parameters = '--storage-driver=devicemapper --storage-opt=dm.thinpooldev=/dev/mapper/docker-thinpool --storage-opt dm.use_deferred_removal=true'

    exec { "umount-${volume}":
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      command => "umount ${volume}",
      onlyif  => "/bin/mount -l | grep -q ${volume}"
    }->

    exec { "create-volume-${volume}":
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      command => "pvcreate ${volume}",
      unless  => "/sbin/lvmdiskscan | grep ${volume}",
    }->
    exec { 'create-volume-group-docker':
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      command => "vgcreate docker ${volume} -y",
      unless  => 'vgdisplay docker',
    }->

    exec { 'create-thinpool':
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      command => 'lvcreate -l 95%VG -T docker/thinpool -n thinpool',
      unless  => 'lvdisplay /dev/docker/thinpool',
    }->

    file { '/etc/lvm/profile/docker-thinpool.profile':
      ensure => file,
      source => 'puppet:///modules/profile/docker-thinpool.profile',
      owner  => 'root',
      group  => 'root',
      mode   => '0644'
    }->
    exec { 'apply-lvm-profile':
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      command => 'lvchange --metadataprofile docker-thinpool docker/thinpool',
      before  => Package['docker'],
    }
  }
  else {
    $storage_parameters = ''
  }

  if '/var/lib/docker' != $docker_home {
    file { '/var/lib/docker':
      ensure  => link,
      target  => $docker_home,
      require => File[$docker_home],
      before  => Package['docker']
    }
  }

  package { 'device-mapper-libs':
    ensure  => latest,
    require => File['/var/lib/docker'],
  }

  if ( $operatingsystemmajrelease == '6' ) {
    exec { "/usr/bin/yum install -y ${docker_rpm}":
      unless => '/bin/rpm -qa | grep docker-io',
      before => [ Package['docker'], Class['docker'] ]
    }
  }

  class { 'docker':
    tcp_bind         => 'tcp://0.0.0.0:2357',
    socket_bind      => 'unix:///var/run/docker.sock',
    require          => File['/var/lib/docker'],
    extra_parameters => [
      "--insecure-registry=${registry}",
      $extra_parameters, $storage_parameters
    ],
  }
}
