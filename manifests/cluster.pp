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
# [*config_dir*]
# Directory with sensu configs
#
# [*lock_timeout*]
# Values close to *check_every*?
#
# [*socket*]
# TCP socket that alerts going to be sent to
#
# For rest see @monitoring_check.
#
#
define monitoring_check::cluster (
    $runbook,
    $cluster,
    $check                 = $name,
    $command_add           = "",
    $config_dir            = "/etc/sensu/conf.d",
    $socket                = "localhost:3030"
    $annotation            = annotate(),
    $check_every           = '1m',
    $lock_timeout          = $check_every,
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
  include monitoring_check::cluster_check
  $human_lock_timeout = human_time_to_seconds($lock_timeout)

  monitoring_check { "${cluster}_${name}":
    command             =>
      "/nail/usr/share/sensu-custom-plugins/check-cluster.rb -N ${cluster} -D ${config_dir}" +
      "-c ${check} -S ${socket} -L ${human_lock_timeout} ${command_add}",
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
    ensure              => $ensure,
    dependencies        => $dependencies
  }
}
