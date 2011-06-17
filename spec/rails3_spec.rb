require File.join(File.expand_path(File.dirname(__FILE__)), 'spec_helper')

gem     'mail'
gem     'actionmailer', '>=3.0.0.beta4'
require 'mail'
require 'action_mailer'
require 'resque_mailer/rails3'

ActionMailer::Base.delivery_method = :test

class Rails3Mailer < ActionMailer::Base
  include Resque::Mailer

  def test_mail(*params)
    mail(*params)
  end
end

share_examples_for "Mail::Message" do
  its(:subject) { should == default_email_params[:subject] }
  its(:from)    { should == [default_email_params[:from]] }
  its(:to)      { should == [default_email_params[:to]] }
end

describe Rails3Mailer do
  let(:default_email_params) do
    {
      :from    => "from@example.com",
      :to      => "to@example.com",
      :subject => "Subject"
    }
  end

  before { Rails3Mailer.stub(:current_env => :test) }

  describe '#deliver' do
    subject { Rails3Mailer.test_mail(default_email_params).deliver }

    before { Resque.stub(:enqueue) }

    it_should_behave_like "Mail::Message"

    it 'should not deliver the email synchronously' do
      lambda { subject }.should_not change(ActionMailer::Base.deliveries, :size)
    end

    it 'should place the deliver action on the Resque "mailer" queue' do
      Resque.should_receive(:enqueue).with(Rails3Mailer, :test_mail, default_email_params)
      subject
    end

    context "when current env is excluded" do
      it 'should not deliver through Resque for excluded environments' do
        Resque::Mailer.stub(:excluded_environments => [:custom])
        Rails3Mailer.should_receive(:current_env).and_return(:custom)
        Resque.should_not_receive(:enqueue)
        subject
      end
    end
  end

  describe '#deliver!' do
    subject { Rails3Mailer.test_mail(default_email_params).deliver! }
    it 'should deliver the email synchronously' do
      lambda { subject }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end

  describe ".perform" do
    subject { Rails3Mailer.perform(:test_mail, default_email_params) }

    it 'should perform a queued mailer job' do
      lambda { subject }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end

  describe "instantiation" do
    subject { Rails3Mailer.test_mail(default_email_params) }

    it_should_behave_like "Mail::Message"
  end
end
