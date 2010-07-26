require "resque_mailer/common"

if defined?(Rails.version) && Rails.version.to_i >= 3
  require "resque_mailer/rails3"
else
  require "resque_mailer/rails2"
end
