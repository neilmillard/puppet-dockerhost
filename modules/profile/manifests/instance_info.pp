class profile::instance_info {

  file { 'instance_info':
    ensure  => file,
    content => template('profile/instance_info.erb'),
    path    => '/usr/local/sbin/instance_info',
    mode    => '0110',
      owner => root,
      group => root,
  }
}
