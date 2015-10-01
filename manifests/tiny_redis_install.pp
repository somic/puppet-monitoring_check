# == Class: monitoring_check::tiny_redis_install
#
#
class monitoring_check::tiny_redis_install (

) inherits monitoring_check::params {

  file { '/etc/sensu/plugins/tiny_redis.rb':
    owner  => $monitoring_check::params::user,
    group  => $monitoring_check::params::group,
    mode   => $monitoring_check::params::file_mode,
    source => 'puppet:///modules/monitoring_check/tiny_redis.rb',
  }
}
