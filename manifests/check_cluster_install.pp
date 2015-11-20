# == Define: monitoring_check::cluster_check_install
#
# Installs a cluster_check script
#
#
class monitoring_check::check_cluster_install {
  include monitoring_check::tiny_redis_install

  file { "${monitoring_check::params::etc_dir}/plugins/check-cluster.rb":
    owner  => $monitoring_check::params::user,
    group  => $monitoring_check::params::group,
    mode   => '0755',
    source => 'puppet:///modules/monitoring_check/check-cluster.rb'
  }
}
