class role::eyamld {
  include ::profile::base
  include ::profile::os_limits
  include ::profile::docker_base
  include ::profile::docker_containers

  stage { 'swapfile':
    before => Stage['main'],
  }

  class { '::profile::swapfile':
    stage => swapfile
  }
}