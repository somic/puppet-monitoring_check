# == Class monitoring_check::server_side
#
# This is like a regular monitoring_check which can be configured to run
# on multiple hosts. All deployments of this check will use
# local sensu's redis to synchronize themselves such that only
# one check will actually execute within each $check_every interval,
# all other checks will be noop during this time interval.
#
# Common use case is when you want to monitor something external from
# many hosts but do not want to receive a flood of events from each deployed check
# in case of failure.
#
# You most likely will want to set :source to some string that is not tied
# to a host on which this check is going to run.
#
# == Examples
#
# monitoring_check::server_side { 'ping_google_dns':
#   command => 'ping -c 1 8.8.8.8 >/dev/null 2>&1',
#   source  => 'datacenter1_devA_environment',
#   runbook => 'runbook/URL/here',
# }
#
# === Parameters
#
# Most parameters are the same as monitoring_check.
#
# [*source*]
# String that identifies this event. Should not be tied to a host that generated
# this event because it can come from any host where this check is deployed.
#
define monitoring_check::server_side (
  $command,
  $runbook,
  $source,
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
  validate_string($source)

  include monitoring_check::server_side::install

  $custom_server_side = {
    actual_command => $command,
    actual_name    => $title,
    source         => $source,
  }

  $new_title = "server_side_placeholder_for_${title}"
  $new_command = "/etc/sensu/plugins/check_server_side.rb -c ${new_title}"

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
    sensu_custom          => merge($sensu_custom, $custom_server_side),
    low_flap_threshold    => $low_flap_threshold,
    high_flap_threshold   => $high_flap_threshold,
    can_override          => $can_override,
    annotation            => $annotation,
  }

}
