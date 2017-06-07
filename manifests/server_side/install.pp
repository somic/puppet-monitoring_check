# == Class: monitoring_check::server_side::install
#
#
class monitoring_check::server_side::install (
) {
  include monitoring_check::tiny_redis_install

  file { "${monitoring_check::params::etc_dir}/plugins/check_server_side.rb":
    owner  => $monitoring_check::params::user,
    group  => $monitoring_check::params::group,
    mode   => '0555',
    source => 'puppet:///modules/monitoring_check/check_server_side.rb',
  }

  file { '/etc/sensu/plugins/fleet_check.rb':
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0444',
    source => 'puppet:///modules/monitoring_check/fleet_check.rb',
  }

  file { '/etc/sensu/plugins/check_remote_sensu.rb':
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/monitoring_check/check_remote_sensu.rb',
  }
}
