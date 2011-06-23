$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'action_mailer'
require 'resque_mailer'
require 'rspec/autorun'

Resque::Mailer.excluded_environments = []
ActionMailer::Base.delivery_method = :test
