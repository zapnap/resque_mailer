$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'action_mailer'
require 'resque_mailer'
require 'active_support/hash_with_indifferent_access'

Resque::Mailer.excluded_environments = []
ActionMailer::Base.delivery_method = :test
ActionMailer::Base.prepend_view_path File.join(File.dirname(__FILE__), 'support')
