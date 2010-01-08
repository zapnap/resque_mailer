require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'rubygems'
gem     'actionmailer', '>= 2.2.2'
require 'action_mailer'

ActionMailer::Base.delivery_method = :test

class AsynchTestMailer < ActionMailer::Base
  include Resque::Mailer
  
  def test_mail(from, to) 
    @subject    = 'subject'
    @body       = 'mail body'
    @recipients = to
    @from       = from
    @sent_on    = Time.now
    @headers    = {}
  end 
end

describe AsynchTestMailer do
  before do
    Object.const_set 'RAILS_ENV', 'test' unless defined?(::RAILS_ENV)
  end 
  
  describe 'deliver_test_mail' do
    before(:each) do
      @emails = ActionMailer::Base.deliveries
      @emails.clear
      @params = 'info@mogoterra.com', 'test@test.net'
      Resque.stub(:enqueue)
    end 
    
    it 'should not deliver the email synchronously' do
      AsynchTestMailer.deliver_test_mail *@params
      @emails.size.should == 0
    end 
    
    it 'should place the deliver action one the Resque mailer queue' do
      Resque.should_receive(:enqueue).with(AsynchTestMailer, 'deliver_test_mail!', *@params)
      AsynchTestMailer.deliver_test_mail *@params
    end 
    
    it 'should not send deliver action to queue for environments where asychronous delivery is disabled' do
      excluded_environments = [:cucumber, :foo, 'bar']
      ::Resque::Mailer.excluded_environments = excluded_environments

      excluded_environments.each do |env|
        Object.send :remove_const, 'RAILS_ENV'
        Object.const_set 'RAILS_ENV', env.to_s

        Resque.should_not_receive(:enqueue)
        AsynchTestMailer.deliver_test_mail *@params
      end
    end
  end

  describe 'deliver_test_mail!' do
    it 'should deliver the mail' do
      emails = ActionMailer::Base.deliveries
      emails.clear
      AsynchTestMailer.deliver_test_mail! 'info@mogoterra.com', 'test@test.net'
      emails.size.should == 1
    end
  end

  it 'should have a queue' do
    AsynchTestMailer.queue.should == :mailer
  end

  it 'should perform a queued mailer job' do
    AsynchTestMailer.should_receive("deliver_test_mail!").with(1, { :foo => 'bar' })
    AsynchTestMailer.perform("deliver_test_mail!", 1, { :foo => 'bar' })
  end
end
