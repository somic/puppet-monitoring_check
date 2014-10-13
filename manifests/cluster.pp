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
# For rest see @monitoring_check.
#
#
define monitoring_check::cluster (
    $cluster,
    $check                 = $name,
    $command_add           = '',
    $runbook               = false,
    $annotation            = annotate(),
    $check_every           = '1m',
    $alert_after           = '0s',
    $realert_every         = '-1',
    $irc_channels          = undef,
    $notification_email    = 'undef',
    $ticket                = false,
    $project               = false,
    $tip                   = false,
    $sla                   = 'No SLA defined.',
    $page                  = false,
    $team                  = 'operations',
    $ensure                = 'present',
    $dependencies          = []
) {
  require monitoring_check::check_cluster_install

  monitoring_check { "${cluster}_${name}":
    ensure              => $ensure,
    command             => '/etc/sensu/plugins/check-cluster.rb' +
      " -N ${cluster} -c ${check} ${command_add}",
    runbook             => $runbook,
    annotation          => $annotation,
    check_every         => $check_every,
    alert_after         => $alert_after,
    realert_every       => $realert_every,
    irc_channels        => $irc_channels,
    notification_email  => $notification_email,
    ticket              => $ticket,
    project             => $project,
    tip                 => $tip,
    sla                 => $sla,
    page                => $page,
    team                => $team,
    dependencies        => $dependencies
  }
}
