# profile::base
class profile::base {
  include ::timezone
  include ::profile::rsyslog
  include ::profile::instance_info

  augeas { 'disable-crond-emails':
    context => '/files/etc/sysconfig/crond',
    changes => 'set CRONDARGS \'"-m off"\'',
    notify  => Service['crond'],
  }
  service { 'crond': }

  case $::operatingsystemmajrelease  {
    '7': { service { 'firewalld': ensure => 'stopped'} }
  }
  package { 'bash': ensure => latest }

  file_line { 'logrotate_del_cron_from_syslog':
    ensure => absent,
    path   => '/etc/logrotate.d/syslog',
    line   => '/var/log/cron'
  }
}
