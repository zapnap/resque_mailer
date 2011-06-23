# encoding: utf-8

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "resque_mailer"
    gem.summary = %Q{Rails plugin for sending asynchronous email with ActionMailer and Resque}
    gem.description = %Q{Rails plugin for sending asynchronous email with ActionMailer and Resque}
    gem.email = "nap@zerosum.org"
    gem.homepage = "http://github.com/zapnap/resque_mailer"
    gem.authors = ["Nick Plante"]
    gem.add_development_dependency "rspec", ">= 2.6.0"
    gem.add_development_dependency "resque", ">= 1.2.3"
    gem.add_development_dependency "actionmailer", ">= 3.0.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::RubygemsDotOrgTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = ["spec/resque_mailer_spec.rb"]
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
