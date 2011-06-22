$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'resque_mailer/common'
require "support/define_constant_helpers"

begin
  require 'rspec/autorun'
rescue LoadError
  require 'spec/autorun'
end

Resque::Mailer.excluded_environments = []
