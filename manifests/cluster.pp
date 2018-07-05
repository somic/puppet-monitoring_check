# == Define: monitoring_check::cluster
#
# A define for managing cluster checks.
#
# === Parameters
#
# [*check*]
# Check name, defaults to $name
#
# [*command_add*]
# Additional command arguments
#
# [*staleness_interval*]
# The cluster check will only count individual check status's of 'OK' if they
# occured within the last staleness_interval. Defaults to 12 hours
#
# For rest see @monitoring_check.
#
#
define monitoring_check::cluster (
    $runbook,
    $check                 = $name,
    $command_add           = '',
    $staleness_interval    = '12h',
    $tip                   = undef,
    $check_every           = undef,
    $alert_after           = undef,
    $realert_every         = undef,
    $slack_channels        = undef,
    $notification_email    = undef,
    $ticket                = undef,
    $project               = undef,
    $sla                   = undef,
    $page                  = undef,
    $team                  = undef,
    $dependencies          = undef,
    $sensu_custom          = undef
) {
  require monitoring_check::check_cluster_install

  require monitoring_check::params
  $cluster = $monitoring_check::params::cluster_name

  $staleness_interval_s = human_time_to_seconds($staleness_interval)
  validate_re($staleness_interval_s, '^\d+$')

  $custom_cluster_params = {
    staleness_interval  => $staleness_interval_s,
  }

  monitoring_check { "${cluster}_${name}":
    command             => "/etc/sensu/plugins/check-cluster.rb  --cluster-name ${cluster} --check ${check} ${command_add}",
    runbook             => $runbook,
    check_every         => $check_every,
    alert_after         => $alert_after,
    realert_every       => $realert_every,
    slack_channels      => $slack_channels,
    notification_email  => $notification_email,
    ticket              => $ticket,
    project             => $project,
    tip                 => $tip,
    sla                 => $sla,
    page                => $page,
    team                => $team,
    dependencies        => $dependencies,
    sensu_custom        => merge($sensu_custom, $custom_cluster_params),
  }
}
