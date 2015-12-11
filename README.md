##Overview

[![Build Status](https://travis-ci.org/Yelp/puppet-monitoring_check.svg?branch=master)](https://travis-ci.org/Yelp/puppet-monitoring_check)

`monitoring_check` is a puppet module to create Sensu checks.

These are special Sensu checks, that are designed to operate with the 
Yelp `sensu_handlers`, for multi-team environments.

The `monitoring_check` definition allows applications to define their behavior,
including how noisy they are, which teams get notified, and how.

## Examples

```puppet
# Page if operations if cron isn't running
monitoring_check { 'cron':
  alert_after => '5m',
  check_every => '1m',
  page        => true,
  team        => 'operations',
  runbook     => 'http://lmgtfy.com/?q=cron',
  command     => "/usr/lib/nagios/plugins/check_procs -C crond -c 1:30 -t 30 ",
  require     => Class['cron']
}
```

## Parameters

Please see `init.pp` for a full list of parameters. They are documented
in the standard puppet doc format.

## Team Data JSON

By default, monitoring_check will expose the Team Data as JSON in 
`/etc/sensu/team_data.json` by accessing the `team_data` key. This file is
designed to be used by non-puppet clients, to help with validation.

However, it could potentially contain sensitive information. It can be disabled by
setting `monitoring_check::params::expose_team_data` to false.

*Note*: Team data is always exposed on the sensu-server.

## Checks that run on sensu servers

`monitoring_check` runs on sensu clients. It is called by `sensu-client` process
on each host it is configured on. In order to support more complex monitoring
scenarios, we built the following types of checks that run on sensu servers.

### Cluster check

Given a name of the event, this check obtains current status of this event
for all clients, discards stale values, calculates percentage of clients
where this event has been triggered and triggers its own event if this
percentage is higher than a configurable threshold.

A common use for this cluster check is where each host runs a check that is
not handled by notification handlers and cluster check is deployed to page
or ticket when this check starts failing on some number of clients. This helps
reduce monitoring noise - as in "don't page when a single web server is slow,
page when many web servers are slow."

See [manifests/cluster.pp](https://github.com/Yelp/puppet-monitoring_check/blob/master/manifests/cluster.pp)

### Server side check

Server side check usually checks something external
to the host it is running on - for example, a piece of hardware that can
be pinged but can't run sensu checks itself.

Common use case could be hit a URL and alert on HTTP 500, for example. Server
side checks have a built-in HA mechanism that ensures a single run of the check
per time period (configurable) regardless of how many sensu servers you have
in this cluster.

See [manifests/server_side.pp](https://github.com/Yelp/puppet-monitoring_check/blob/master/manifests/server_side.pp)

### Fleet check

Fleet check runs on sensu servers. It's meant for situations where it's
desirable to run the check in centralized location but trigger separate events
for individual clients.

For example, you could have a script that talks to cloud provider API, obtains
a list of hosts, checks something and then triggers events for each client
individually.

Another use case could be something like "trigger some event for
the slowest 5% of clients of a certain type (say, database servers)."

See [files/fleet_check.rb](https://github.com/Yelp/puppet-monitoring_check/blob/master/files/fleet_check.rb)

## Limitations / Explanation

This wrapper *only* works with the Yelp handlers. The secret is that a sensu 
check can declare arbitrary key-value pairs in its event data.

Then, the special handlers can pick up these key-values and make decisions based
on them. 

For example, `monitoring_check` can set a `notification_email` entry, and
the Yelp email handler can pick up on this entry and send emails specifically
to the specified email address. 

Contrast this with traditional sensu handlers, where the destination email
address is configuration the *handler*, not the check. 

## License

Apache 2.

## Contributing

Open an [issue](https://github.com/Yelp/puppet-monitoring_check/issues) or 
[fork](https://github.com/Yelp/puppet-monitoring_check/fork) and open a 
[Pull Request](https://github.com/Yelp/puppet-monitoring_check/pulls)

Please do not attempt to use `monitoring_check` without Yelp's `sensu_handlers`
unless you intend to write your own custom handlers.
