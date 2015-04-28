# == Class: monitoring_check::server_side::install
#
#
class monitoring_check::server_side::install (
  $sensu_checks_dir  = '/etc/sensu/conf.d/checks',
  $sensu_client_port = 3030,
  $redis_server,
  $redis_port        = 6379,
) {
  file { '/etc/sensu/plugins/tiny_redis.rb':
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0444',
    source => 'puppet:///modules/monitoring_check/tiny_redis.rb',
  }

  file { '/etc/sensu/plugins/check_server_side.rb':
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/monitoring_check/check_server_side.rb',
  }

  file { '/etc/sensu/conf.d/synchronized.json':
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0444',
    content => template('monitoring_check/synchronized.json.erb'),
  }
}
