# == Class: monitoring_check::tiny_redis_install
#
#
class monitoring_check::tiny_redis_install (
) {
  file { '/etc/sensu/plugins/tiny_redis.rb':
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0444',
    source => 'puppet:///modules/monitoring_check/tiny_redis.rb',
  }
}
