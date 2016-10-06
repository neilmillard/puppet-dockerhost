# volumeDir
define profile::volumeDir {
  $split_out = split($name, ':')
  $split_name = $split_out[0]
  if ! defined( File[$split_name] ) {
    file { $split_name:
      ensure => directory, mode => '0600',
    }
  }
}