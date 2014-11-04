# == Class monitoring_check::params
#
# The params class of monitoring_check allows you to set the defaults for your
# environment once, which are then inherited by all the other monitoring_check
# defines
#
# == Parameters
#
# [*expose_team_data*]
#  Bool to have a json deposited in /etc/sensu/teams.json for other tools
#  to use.
#
# [*team_data*]
#  Hash of team data from sensu_handlers so we can validate incoming teams.
#
class monitoring_check::params (
  $expose_team_data = true,
  # Pull the team data configuration from the sensu_handlers module in order
  # to validate the given inputs.
  $team_data = hiera('sensu_handlers::teams', {})
) {

  # Expose the team metadata as json for other tools to validate against
  validate_bool($expose_team_data)
  validate_hash($team_data)
  if $expose_team_data {
    file { '/etc/sensu/teams.json':
      owner   => 'sensu',
      group   => 'sensu',
      mode    => '0444',
      content => inline_template('<%= require "json"; JSON.generate @team_data %>'),
    }
  }

}
