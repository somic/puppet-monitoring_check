class cluster_check {
  file { "/nail/usr/share/sensu-custom-plugins":
    ensure => directory
  } ->
  file { "/nail/usr/share/sensu-custom-plugins/check_cluster.rb":
    mode   => "0755",
    source => "puppet:///modules/monitoring_check/check_cluster.rb"
  }
}
