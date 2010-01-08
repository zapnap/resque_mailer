require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "resque_mailer"
    gem.summary = %Q{Rails plugin for sending asynchronous email with ActionMailer and Resque}
    gem.description = %Q{Rails plugin for sendings asynchronous email with ActionMailer and Resque}
    gem.email = "nap@zerosum.org"
    gem.homepage = "http://github.com/zapnap/resque_mailer"
    gem.authors = ["Nick Plante"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "resque", ">= 1.2.3"
    gem.add_development_dependency "actionmailer", ">= 2.2.2"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "resque_mailer #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
