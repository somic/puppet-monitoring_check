# == Class: monitoring_check::synchronized::install
#
#
class monitoring_check::synchronized::install (
  $sensu_checks_dir  = '/etc/sensu/conf.d/checks',
  $sensu_client_port = 3030,
  $redis_server,
  $redis_port        = 6379,
) {
  file { '/etc/sensu/plugins/lib':
    owner  => 'sensu',
    group  => 'sensu',
    ensure => 'directory',
    purge  => true,
  }

  file { '/etc/sensu/plugins/lib/tiny_redis.rb':
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0444',
    source => 'puppet:///modules/monitoring_check/lib/tiny_redis.rb',
  }

  file { '/etc/sensu/plugins/check-synchronized.rb':
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/monitoring_check/check-synchronized.rb',
  }

  file { '/etc/sensu/conf.d/synchronized.json':
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0444',
    content => template('monitoring_check/synchronized.json.erb'),
  }
}
