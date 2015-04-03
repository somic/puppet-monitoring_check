# == Define: monitoring_check::synchronized_install
#
#
class monitoring_check::synchronized_install {
  file { '/etc/sensu/plugins/lib':
    owner  => 'sensu',
    group  => 'sensu',
    ensure => 'directory',
    purge  => true,
  } ->

  file { '/etc/sensu/plugins/lib/tiny_redis.rb':
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0644',
    source => 'puppet:///modules/monitoring_check/lib/tiny_redis.rb',
  }

  file { '/etc/sensu/plugins/check-synchronized.rb':
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0755',
    source => 'puppet:///modules/monitoring_check/check-synchronized.rb',
  }
}
