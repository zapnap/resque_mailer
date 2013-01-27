require 'spec_helper'

class FakeResque
  def self.enqueue(*args); end
end

class FakeResqueWithScheduler < FakeResque
  def self.enqueue_in(time, *args); end
  def self.enqueue_at(time, *args); end
end

class Rails3Mailer < ActionMailer::Base
  include Resque::Mailer
  default :from => "from@example.org", :subject => "Subject"
  MAIL_PARAMS = { :to => "crafty@example.org" }

  def test_mail(*params)
    Resque::Mailer.success!
    mail(*params)
  end
end

class PriorityMailer < Rails3Mailer
  self.queue = 'priority_mailer'
end

describe Resque::Mailer do
  let(:resque) { FakeResque }

  before do
    Resque::Mailer.default_queue_target = resque
    Resque::Mailer.fallback_to_synchronous = false
    Resque::Mailer.stub(:success!)
    Resque::Mailer::MessageDecoy.any_instance.stub(:current_env).and_return(:test)
  end

  describe "resque" do
    it "allows overriding of the default queue target (for testing)" do
      Resque::Mailer.default_queue_target = FakeResque
      Rails3Mailer.resque.should == FakeResque
    end
  end

  describe "queue" do
    it "defaults to the 'mailer' queue" do
      Rails3Mailer.queue.should == "mailer"
    end

    it "allows overriding of the default queue name" do
      Resque::Mailer.default_queue_name = "postal"
      Rails3Mailer.queue.should == "postal"
    end

    it "allows overriding of the local queue name" do
      PriorityMailer.queue.should == "priority_mailer"
    end
  end

  describe '#deliver' do
    before(:all) do
      @delivery = lambda {
        Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver
      }
    end

    it 'should not deliver the email synchronously' do
      lambda { @delivery.call }.should_not change(ActionMailer::Base.deliveries, :size)
    end

    it 'should place the deliver action on the Resque "mailer" queue' do
      resque.should_receive(:enqueue).with(Rails3Mailer, :test_mail, Rails3Mailer::MAIL_PARAMS)
      @delivery.call
    end

    context "when current env is excluded" do
      it 'should not deliver through Resque for excluded environments' do
        Resque::Mailer.stub(:excluded_environments => [:custom])
        Resque::Mailer::MessageDecoy.any_instance.should_receive(:current_env).twice.and_return(:custom)
        resque.should_not_receive(:enqueue)
        @delivery.call
      end
    end

    it 'should not invoke the method body more than once' do
      Resque::Mailer.should_not_receive(:success!)
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver
    end

    context "when fallback_to_synchronous is true" do
      before do
        Resque::Mailer.fallback_to_synchronous = true
      end

      context "when redis is not available" do
        before do
          Resque::Mailer.default_queue_target.stub(:enqueue).and_raise(Errno::ECONNREFUSED)
        end

        it 'should deliver the email synchronously' do
          lambda { @delivery.call }.should change(ActionMailer::Base.deliveries, :size).by(1)
        end
      end
    end
  end

  describe '#deliver_at' do
    before(:all) do
      @time = Time.now
      @delivery = lambda {
        Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver_at(@time)
      }
    end

    context "without resque-scheduler installed" do
      it "raises an error" do
        lambda { @delivery.call }.should raise_exception
      end
    end

    context "with resque-scheduler installed" do
      let(:resque) { FakeResqueWithScheduler }

      it 'should not deliver the email synchronously' do
        lambda { @delivery.call }.should_not change(ActionMailer::Base.deliveries, :size)
      end

      it 'should place the deliver action on the Resque "mailer" queue' do
        resque.should_receive(:enqueue_at).with(@time, Rails3Mailer, :test_mail, Rails3Mailer::MAIL_PARAMS)
        @delivery.call
      end

      context "when current env is excluded" do
        it 'should not deliver through Resque for excluded environments' do
          Resque::Mailer.stub(:excluded_environments => [:custom])
          Resque::Mailer::MessageDecoy.any_instance.should_receive(:current_env).twice.and_return(:custom)
          resque.should_not_receive(:enqueue_at)
          @delivery.call
        end
      end
    end
  end

  describe '#deliver_in' do
    before(:all) do
      @time = 1234567
      @delivery = lambda {
        Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver_in(@time)
      }
    end

    context "without resque-scheduler installed" do
      it "raises an error" do
        lambda { @delivery.call }.should raise_exception
      end
    end

    context "with resque-scheduler installed" do
      let(:resque) { FakeResqueWithScheduler }

      it 'should not deliver the email synchronously' do
        lambda { @delivery.call }.should_not change(ActionMailer::Base.deliveries, :size)
      end

      it 'should place the deliver action on the Resque "mailer" queue' do
        resque.should_receive(:enqueue_in).with(@time, Rails3Mailer, :test_mail, Rails3Mailer::MAIL_PARAMS)
        @delivery.call
      end

      context "when current env is excluded" do
        it 'should not deliver through Resque for excluded environments' do
          Resque::Mailer.stub(:excluded_environments => [:custom])
          Resque::Mailer::MessageDecoy.any_instance.should_receive(:current_env).twice.and_return(:custom)
          resque.should_not_receive(:enqueue_in)
          @delivery.call
        end
      end
    end
  end

  describe '#deliver!' do
    it 'should deliver the email synchronously' do
      lambda { Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver! }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end

  describe 'perform' do
    it 'should perform a queued mailer job' do
      lambda {
        Rails3Mailer.perform(:test_mail, Rails3Mailer::MAIL_PARAMS)
      }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end

    context "when job fails" do
      let(:message) { mock(:message) }
      let(:mailer) { mock(:mailer, :message => message) }
      let(:logger) { mock(:logger, :error => nil) }
      let(:exception) { Exception.new("An error") }

      before(:each) do
        Rails3Mailer.logger = logger
        Rails3Mailer.stub(:new) { mailer }
        message.stub(:deliver).and_raise(exception)
      end

      subject { Rails3Mailer.perform(:test_mail, Rails3Mailer::MAIL_PARAMS) }

      it "raises and logs the exception" do
        logger.should_receive(:error).at_least(:once)
        expect { subject }.to raise_error(exception)
      end

      context "when error_handler set" do
        before(:each) do
          Resque::Mailer.error_handler = lambda { |mailer, message, exception|
            @mailer = mailer
            @message = message
            @exception = exception
          }
        end

        it "should pass the mailer to the handler" do
          subject
          @mailer.should eq(Rails3Mailer)
        end

        it "should pass the message to the handler" do
          subject
          @message.should eq(message)
        end

        it "should pass the exception to the handler" do
          subject
          @exception.should eq(exception)
        end
      end
    end
  end

  describe 'original mail methods' do
    it 'should be preserved' do
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).subject.should == 'Subject'
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).from.should include('from@example.org')
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).to.should include('crafty@example.org')
    end

    it 'should require execution of the method body prior to queueing' do
      Resque::Mailer.should_receive(:success!).once
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).subject
    end
    context "when current env is excluded" do
      it 'should render email immediately' do
        Resque::Mailer::MessageDecoy.any_instance.stub(:environment_excluded?).and_return(true)
        resque.should_not_receive(:enqueue_in)
        params = {:subject => 'abc'}
        mail = Rails3Mailer.test_mail(params)
        params[:subject] = 'xyz'
        mail.to_s.should match('Subject: abc')
      end
    end
  end
end
