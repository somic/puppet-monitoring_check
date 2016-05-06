# == Define: monitoring_check::remediation
#
# Installs the remediation check
#
#
class monitoring_check::remediation {
  file { "${monitoring_check::params::etc_dir}/plugins/remediation.sh":
    owner  => $monitoring_check::params::user,
    group  => $monitoring_check::params::group,
    mode   => '0755',
    source => 'puppet:///modules/monitoring_check/remediation.sh',
  }
}
