source 'https://rubygems.org'

gem 'rake'
gem 'puppet-lint'
gem 'rspec'
gem 'rspec-puppet'
gem 'rspec-system-puppet'
gem 'puppetlabs_spec_helper'
gem 'travis'
gem 'travis-lint'
gem 'puppet-syntax'
gem 'puppet', ENV['PUPPET_VERSION'] || '~> 3.8.0'
gem 'vagrant-wrapper'
gem 'rspec-puppet-utils'
gem 'listen', '< 3.1'

gem 'hiera-puppet-helper',
  :git => 'https://github.com/bobtfish/hiera-puppet-helper.git',
  :ref => '5ed989a130bc62cc6bdb923596586284f0bd73df'

group :development do
  gem "puppet-blacksmith"
  gem "guard-rake"
end
