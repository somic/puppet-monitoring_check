# == Define: monitoring_check::synchronized
#
# === Parameters
#
# See parameters for monitoring_check
#
define monitoring_check::synchronized (
  $command,
  $runbook,
  # monitoring_check optional params
  $needs_sudo            = false,
  $sudo_user             = 'root',
  $check_every           = '1m',
  $timeout               = undef,
  $alert_after           = '0s',
  $realert_every         = '-1',
  $team                  = 'operations',
  $page                  = false,
  $irc_channels          = undef,
  $notification_email    = 'undef',
  $ticket                = false,
  $project               = false,
  $tip                   = false,
  $sla                   = 'No SLA defined.',
  $dependencies          = [],
  $use_sensu             = hiera('sensu_enabled', true),
  $sensu_custom          = {},
  $low_flap_threshold    = undef,
  $high_flap_threshold   = undef,
  $can_override          = true,
  $annotation            = annotation_guess(),
) {

  include monitoring_check::synchronized::install

  $custom_synchronized = {
    actual_command => $command,
    actual_name    => $title,
  }

  $new_title = "synchronized_placeholder_for_${title}"

  $new_commandd = "/etc/sensu/plugins/check-synchronized.rb -f /etc/sensu/conf.d/synchronized.json -c ${new_title}"

  monitoring_check { $new_title:
    command               => $new_command,
    runbook               => $runbook,
    needs_sudo            => $needs_sudo,
    sudo_user             => $sudo_user,
    check_every           => $check_every,
    timeout               => $timeout,
    alert_after           => $alert_after,
    realert_every         => $realert_every,
    team                  => $team,
    page                  => $page,
    irc_channels          => $irc_channels,
    notification_email    => $notification_email,
    ticket                => $ticket,
    project               => $project,
    tip                   => $tip,
    sla                   => $sla,
    dependencies          => $dependencies,
    use_sensu             => $use_sensu,
    sensu_custom          => $sensu_custom.merge($custom_synchronized),
    low_flap_threshold    => $low_flap_threshold,
    high_flap_threshold   => $high_flap_threshold,
    can_override          => $can_override,
    annotation            => $annotation,
  }

}
