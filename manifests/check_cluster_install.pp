# == Define: monitoring_check::cluster_check_install
#
# Installs a cluster_check script
#
#
class monitoring_check::check_cluster_install {
  include monitoring_check::tiny_redis_install

  file { '/etc/sensu/plugins/check-cluster.rb':
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0755',
    source => 'puppet:///modules/monitoring_check/check-cluster.rb'
  }
}
