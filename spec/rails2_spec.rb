require File.join(File.expand_path(File.dirname(__FILE__)), 'spec_helper')

gem     'actionmailer', '~>2.3.4'
require 'action_mailer'
require 'resque_mailer/rails2'

ActionMailer::Base.delivery_method = :test

class Rails2Mailer < ActionMailer::Base
  include Resque::Mailer
  MAIL_PARAMS = { :to => "misio@example.org" }

  def test_mail(opts={})
    @subject    = 'subject'
    @body       = 'mail body'
    @recipients = opts[:to]
    @from       = 'from@example.org'
    @sent_on    = Time.now
    @headers    = {}
  end
end

describe Rails2Mailer do
  before do
    Rails2Mailer.stub(:current_env => :test)
  end

  describe '#deliver' do
    before(:all) do
      @delivery = lambda {
        Rails2Mailer.deliver_test_mail(Rails2Mailer::MAIL_PARAMS)
      }
    end

    before(:each) do
      Resque.stub(:enqueue)
    end

    it 'should not deliver the email synchronously' do
      lambda { @delivery.call }.should_not change(ActionMailer::Base.deliveries, :size)
    end

    it 'should place the deliver action on the Resque "mailer" queue' do
      Resque.should_receive(:enqueue).with(Rails2Mailer, "deliver_test_mail!", Rails2Mailer::MAIL_PARAMS)
      @delivery.call
    end

    context "when current env is excluded" do
      it 'should not deliver through Resque for excluded environments' do
        Resque::Mailer.stub(:excluded_environments => [:custom])
        Rails2Mailer.should_receive(:current_env).and_return(:custom)
        Resque.should_not_receive(:enqueue)
        @delivery.call
      end
    end
  end

  describe '#deliver!' do
    it 'should deliver the email synchronously' do
      lambda { Rails2Mailer.deliver_test_mail!(Rails2Mailer::MAIL_PARAMS) }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end

  describe ".perform" do
    it 'should perform a queued mailer job' do
      lambda {
        Rails2Mailer.perform("deliver_test_mail!", Rails2Mailer::MAIL_PARAMS)
      }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end
end
