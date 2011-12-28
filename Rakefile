require 'bundler'

Bundler.setup(:default, :development)

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = ["spec/resque_mailer_spec.rb"]
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new

desc "Push a new version to Rubygems"
task :publish do
  require 'resque_mailer/version'

  sh "gem build resque_mailer.gemspec"
  sh "gem push resque_mailer-#{Resque::Mailer::VERSION}.gem"
  sh "rm resque_mailer-#{Resque::Mailer::VERSION}.gem"
  sh "git tag v#{Resque::Mailer::VERSION}"
  sh "git push origin v#{Resque::Mailer::VERSION}"
  sh "git push origin master"
end
