# profile::docker_containers
class profile::docker_containers ($containers={}) {


  create_resources ( 'profile::docker_container', $containers )
}
