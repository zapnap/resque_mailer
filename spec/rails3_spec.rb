require File.join(File.expand_path(File.dirname(__FILE__)), 'spec_helper')

gem     'actionmailer', '>=3.0.0.beta4'
require 'action_mailer'
require 'resque_mailer/rails3'

ActionMailer::Base.delivery_method = :test

class Rails3Mailer < ActionMailer::Base
  include Resque::Mailer
  default :from => "from@example.org", :subject => "Subject"
  MAIL_PARAMS = { :to => "misio@example.org" }

  def test_mail(*params)
    mail(*params)
  end
end

describe Rails3Mailer do
  before do
    Rails3Mailer.stub(:current_env => :test)
  end

  describe '#deliver' do
    before(:all) do
      @delivery = lambda {
        Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver
      }
    end

    before(:each) do
      Resque.stub(:enqueue)
    end

    it 'should not deliver the email synchronously' do
      lambda { @delivery.call }.should_not change(ActionMailer::Base.deliveries, :size)
    end

    it 'should place the deliver action on the Resque "mailer" queue' do
      Resque.should_receive(:enqueue).with(Rails3Mailer, :test_mail, Rails3Mailer::MAIL_PARAMS)
      @delivery.call
    end

    context "when current env is excluded" do
      it 'should not deliver through Resque for excluded environments' do
        Resque::Mailer.stub(:excluded_environments => [:custom])
        Rails3Mailer.should_receive(:current_env).and_return(:custom)
        Resque.should_not_receive(:enqueue)
        @delivery.call
      end
    end
  end

  describe '#deliver!' do
    it 'should deliver the email synchronously' do
      lambda { Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver! }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end

  describe ".perform" do
    it 'should perform a queued mailer job' do
      lambda {
        Rails3Mailer.perform(:test_mail, Rails3Mailer::MAIL_PARAMS)
      }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end
end
