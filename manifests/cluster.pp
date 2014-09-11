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
# [*server_config*]
# JSON file that has sensu-server redis configuration
#
# [*lock_timeout*]
# Values close to *check_every*?
#
# For rest see @monitoring_check.
#
#
define monitoring_check::cluster (
    $runbook,
    $check                 = $name,
    $command_add           = "",
    $server_config         = "/etc/sensu/config.json",
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
    $needs_sudo            = false,
    $sudo_user             = 'root',
    $team                  = 'operations',
    $ensure                = 'present',
    $dependencies          = [],
    $low_flap_threshold    = undef,
    $high_flap_threshold   = undef,
    $aggregate             = false,
    $sensu_custom          = {}
) {
  include monitoring_check::cluster_check
  $human_lock_timeout = human_time_to_seconds($lock_timeout)

  monitoring_check { "cluster::${name}":
    command             =>
      "/nail/usr/share/sensu-custom-plugins/check_cluster.rb " +
      "-c ${check} -S ${server_config} -L ${human_lock_timeout} ${command_add}",
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
    needs_sudo          => $needs_sudo,
    sudo_user           => $sudo_user,
    team                => $team,
    ensure              => $ensure,
    dependencies        => $dependencies,
    low_flap_threshold  => $low_flap_threshold,
    high_flap_threshold => $high_flap_threshold,
    aggregate           => $aggregate,
    sensu_custom        => merge({source => $name}, $sensu_custom)
  }
}
