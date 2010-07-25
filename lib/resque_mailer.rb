require "resque_mailer/common"

if defined? Rails.root
  require "resque_mailer/rails3"
else
  require "resque_mailer/rails2"
end
