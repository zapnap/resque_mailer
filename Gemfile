source 'http://rubygems.org'

gemspec

rails_version = ENV["RAILS_VERSION"] || "default"

rails = case rails_version
when "master"
  {github: "rails/rails"}
when "default"
  "~> 3.2.0"
else
  "~> #{rails_version}"
end

gem 'actionmailer', rails

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem 'rake', '~> 0.9'
end
