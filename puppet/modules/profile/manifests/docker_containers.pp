# profile::docker_containers
class profile::docker_containers ($containers={}) {
  # volumeDir
  define volumeDir {
    $split_out = split($name, ':')
    $split_name = $split_out[0]
    if ! defined( File[$split_name] ) {
      file { $split_name:
        ensure => directory, mode => '0600',
      }
    }
  }

  # docker_container
  define docker_container (
      $image,
      $container=$title,
      $command = undef,
      $memory_limit = '0b',
      $cpuset = [],
      $ports = [],
      $expose = [],
      $volumes = [],
      $links = [],
      $use_name = false,
      $running = true,
      $volumes_from = [],
      $net = 'bridge',
      $username = false,
      $hostname = false,
      $env = [],
      $dns = [],
      $dns_search = [],
      $lxc_conf = [],
      $restart_service = true,
      $disable_network = false,
      $privileged = false,
      $detach = true,
      $extra_parameters = undef,
      $pull_on_start = false,
      $depends = [],
      $tty = false,
      $requires = [],
      $manage_volume = true,
    ) {

    if $manage_volume {
        volumeDir { $volumes: }
            VolumeDir<| |> -> Service['docker']
        }

    Service['docker']
    ->
    docker::run { $container:
      image            => $image,
      command          => $command,
      memory_limit     => $memory_limit,
      cpuset           => $cpuset,
      ports            => $ports,
      expose           => $expose,
      volumes          => $volumes,
      links            => $links,
      use_name         => $use_name,
      running          => $running,
      volumes_from     => $volumes_from,
      net              => $net,
      username         => $username,
      hostname         => $hostname,
      env              => $env,
      dns              => $dns,
      dns_search       => $dns_search,
      lxc_conf         => $lxc_conf,
      restart_service  => $restart_service,
      disable_network  => $disable_network,
      privileged       => $privileged,
      detach           => $detach,
      extra_parameters => $extra_parameters,
      pull_on_start    => $pull_on_start,
      depends          => $depends,
      tty              => $tty,
      require          => $requires,
    }
  }

  create_resources ( 'docker_container', $containers )
}
