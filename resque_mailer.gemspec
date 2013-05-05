# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "resque_mailer/version"

Gem::Specification.new do |s|
  s.name        = "resque_mailer"
  s.version     = Resque::Mailer::VERSION
  s.authors     = ["Nick Plante"]
  s.email       = ["nap@zerosum.org"]
  s.homepage    = "http://github.com/zapnap/resque_mailer"
  s.summary     = "Rails plugin for sending asynchronous email with ActionMailer and Resque."
  s.description = "Rails plugin for sending asynchronous email with ActionMailer and Resque."

  s.add_dependency("actionmailer", ">= 3.0")
  s.add_development_dependency("rspec", "~> 2.6")
  s.add_development_dependency("yard", ">= 0.6.0")

  s.extra_rdoc_files = %w(LICENSE CHANGELOG.md README.md)
  s.files            = Dir.glob("lib/**/*") + %w(README.md LICENSE CHANGELOG.md)
end
