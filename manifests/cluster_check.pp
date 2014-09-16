class cluster_check {
  file { "/nail/usr/share/sensu-custom-plugins":
    ensure => directory
  } ->
  file { "/nail/usr/share/sensu-custom-plugins/check-cluster.rb":
    mode   => "0755",
    source => "puppet:///modules/monitoring_check/check-cluster.rb"
  }
}
