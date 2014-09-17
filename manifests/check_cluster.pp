class monitoring_check::check_cluster {
  file { "/etc/sensu/plugins/check-cluster.rb":
    mode   => "0755",
    source => "puppet:///modules/monitoring_check/check-cluster.rb"
  }
}
