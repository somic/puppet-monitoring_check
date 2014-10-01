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

##Parameters

Please see `init.pp` for a full list of parameters. They are documented
in the standard puppet doc format.

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
