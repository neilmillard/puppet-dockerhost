# profile::rsyslog
class profile::rsyslog(
  $server,
  $port = 514,
  $remote_type = 'udp' ,
  $log_local = true,
){
  $remote_servers = []
  $client_name = $hostname

  class{'rsyslog::client':
    log_local      => $log_local,
    remote_servers => $remote_servers,
    log_templates  => [
      {
        name     => 'namespace',
        template => "<%PRI%>%TIMESTAMP:::date-rfc3339% ${client_name} %syslogtag:1:32%%msg:::sp-if-no-1st-sp%%msg%",
      },
    ]
  }
}
