require 'spec_helper'

class FakeResque
  def self.enqueue(*args); end
end

class FakeResqueWithScheduler < FakeResque
  def self.enqueue_in(time, *args); end
  def self.enqueue_at(time, *args); end
  def self.remove_delayed(klass, *args); end
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

class TestSerializer
  def self.serialize(*args)
    args.unshift("test")
  end

  def self.deserialize(data)
    args.shift
    args
  end
end

describe Resque::Mailer do
  let(:resque) { FakeResque }
  let(:logger) { double(:logger, :error => nil) }

  before do
    Resque::Mailer.default_queue_target = resque
    allow(Resque::Mailer).to receive(:success!)
    allow(Resque::Mailer).to receive(:current_env).and_return(:test)
    Rails3Mailer.logger = logger
  end

  describe "resque" do
    it "allows overriding of the default queue target (for testing)" do
      Resque::Mailer.default_queue_target = FakeResque
      expect(Rails3Mailer.resque).to eq FakeResque
    end
  end

  describe "queue" do
    it "defaults to the 'mailer' queue" do
      expect(Rails3Mailer.queue).to eq "mailer"
    end

    it "allows overriding of the default queue name" do
      Resque::Mailer.default_queue_name = "postal"
      expect(Rails3Mailer.queue).to eq "postal"
    end

    it "allows overriding of the local queue name" do
      expect(PriorityMailer.queue).to eq "priority_mailer"
    end
  end

  describe '#deliver' do
    before(:all) do
      @delivery = lambda {
        Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver
      }
    end

    it 'delivers the email synchronously' do
      expect { @delivery.call }.to_not change(ActionMailer::Base.deliveries, :size)
    end

    it 'places the deliver action on the Resque "mailer" queue' do
      expect(resque).to receive(:enqueue).with(Rails3Mailer, :test_mail, Resque::Mailer.argument_serializer.serialize(Rails3Mailer::MAIL_PARAMS))
      @delivery.call
    end

    context 'when current env is excluded' do
      it 'does not deliver through Resque for excluded environments' do
        Resque::Mailer.excluded_environments = [:custom]
        expect_any_instance_of(Resque::Mailer::MessageDecoy).to receive(:current_env).twice.and_return(:custom)
        expect(resque).to_not receive(:enqueue)
        @delivery.call
      end
    end

    it 'does not invoke the method body more than once' do
      expect(Resque::Mailer).to_not receive(:success!)
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver
    end

    context "when redis is not available" do
      context 'using v2' do
        it 'falls back to synchronous delivery automatically' do
          allow(Resque::Mailer.default_queue_target).to receive(:enqueue).and_raise(Errno::ECONNREFUSED)
          expect(logger).to receive(:error).at_least(:once)
          expect { @delivery.call }.to change(ActionMailer::Base.deliveries, :size).by(1)
        end
      end

      context 'using v3' do
        module Redis
          class CannotConnectError < RuntimeError; end
        end

        it 'falls back to synchronous delivery automatically' do
          allow(Resque::Mailer.default_queue_target).to receive(:enqueue).and_raise(Redis::CannotConnectError)
          expect(logger).to receive(:error).at_least(:once)
          expect { @delivery.call }.to change(ActionMailer::Base.deliveries, :size).by(1)
        end
      end
    end
  end

  describe '#unschedule_delivery' do
    before(:all) do
      @unschedule = lambda {
        Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).unschedule_delivery
      }
    end

    context "without reque-schedule installed" do
      it 'raises an error' do
        expect { @unschedule.call }.to raise_exception(RuntimeError)
      end
    end

    context "with resqueue-scheduler" do
      let(:resque) { FakeResqueWithScheduler }

      it 'unschedules email' do
        expect(resque).to receive(:remove_delayed).with(Rails3Mailer, :test_mail, Resque::Mailer.argument_serializer.serialize(Rails3Mailer::MAIL_PARAMS))
        @unschedule.call
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
        expect { @delivery.call }.to raise_exception(RuntimeError)
      end
    end

    context "with resque-scheduler installed" do
      let(:resque) { FakeResqueWithScheduler }

      it 'does not deliver the email synchronously' do
        expect { @delivery.call }.to_not change(ActionMailer::Base.deliveries, :size)
      end

      it 'places the deliver action on the Resque "mailer" queue' do
        expect(resque).to receive(:enqueue_at).with(@time, Rails3Mailer, :test_mail, Resque::Mailer.argument_serializer.serialize(Rails3Mailer::MAIL_PARAMS))
        @delivery.call
      end

      context "when current env is excluded" do
        it 'does not deliver through Resque for excluded environments' do
          allow(Resque::Mailer).to receive(:excluded_environments).and_return([:custom])
          expect_any_instance_of(Resque::Mailer::MessageDecoy).to_not receive(:current_env).twice.and_return(:custom)
          expect(resque).to_not receive(:enqueue_at)
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
        expect { @delivery.call }.to raise_exception(RuntimeError)
      end
    end

    context "with resque-scheduler installed" do
      let(:resque) { FakeResqueWithScheduler }

      it 'does not deliver the email synchronously' do
        expect { @delivery.call }.to_not change(ActionMailer::Base.deliveries, :size)
      end

      it 'places the deliver action on the Resque "mailer" queue' do
        expect(resque).to receive(:enqueue_in).with(@time, Rails3Mailer, :test_mail, Resque::Mailer.argument_serializer.serialize(Rails3Mailer::MAIL_PARAMS))
        @delivery.call
      end

      context "when current env is excluded" do
        it 'does not deliver through Resque for excluded environments' do
          allow(Resque::Mailer).to receive(:excluded_environments).and_return([:custom])
          expect_any_instance_of(Resque::Mailer::MessageDecoy).to receive(:current_env).twice.and_return(:custom)
          expect(resque).to_not receive(:enqueue_in)
          @delivery.call
        end
      end
    end
  end

  describe '#deliver!' do
    it 'delivers the email synchronously' do
      expect { Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver! }.to change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end

  describe 'perform' do
    it 'performs a queued mailer job' do
      expect {
        Rails3Mailer.perform(:test_mail, Resque::Mailer.argument_serializer.serialize(Rails3Mailer::MAIL_PARAMS))
      }.to change(ActionMailer::Base.deliveries, :size).by(1)
    end

    context "when job fails" do
      let(:message) { double(:message) }
      let(:mailer) { double(:mailer, :message => message) }
      let(:exception) { Exception.new("An error") }

      before(:each) do
        allow(Rails3Mailer).to receive(:new) { mailer }
        allow(message).to receive(:deliver).and_raise(exception)
        allow(mailer).to receive(:process)
        allow(mailer).to receive(:message) { message }
      end

      subject { Rails3Mailer.perform(:test_mail, Rails3Mailer::MAIL_PARAMS) }

      it "raises and logs the exception" do
        expect(logger).to receive(:error).at_least(:once)
        expect { subject }.to raise_error(exception)
      end

      context "when error_handler set" do
        before(:each) do
          Resque::Mailer.error_handler = lambda { |mailer, message, exception, action, args|
            @mailer = mailer
            @message = message
            @exception = exception
            @action = action
            @args = args
          }
        end

        it "passes the mailer to the handler" do
          subject
          expect(@mailer).to eq(Rails3Mailer)
        end

        it "passes the message to the handler" do
          subject
          expect(@message).to eq(message)
        end

        it "passes the action to the handler" do
          subject
          expect(@action).to eq(:test_mail)
        end

        it "passes the args to the handler" do
          subject
          expect(@args).to eq(Rails3Mailer::MAIL_PARAMS)
        end

        it "passes the exception to the handler" do
          subject
          expect(@exception).to eq(exception)
        end
      end
    end
  end

  describe 'original mail methods' do
    it 'is preserved' do
      expect(Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).subject).to eq 'Subject'
      expect(Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).from).to include('from@example.org')
      expect(Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).to).to include('crafty@example.org')
    end

    it 'requires execution of the method body prior to queueing' do
      expect(Resque::Mailer).to receive(:success!).once
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).subject
    end

    context "when current env is excluded" do
      it 'renders email immediately' do
        allow_any_instance_of(Resque::Mailer::MessageDecoy).to receive(:environment_excluded?).and_return(true)
        expect(resque).to_not receive(:enqueue_in)
        params = {:subject => 'abc'}
        mail = Rails3Mailer.test_mail(params)
        params[:subject] = 'xyz'
        expect(mail.to_s).to match('Subject: abc')
      end
    end
  end

  describe '#respond_to?' do
    it 'admits to responding to its own methods' do
      expect(Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).respond_to?(:deliver_at)).to eq true
    end

    it 'admits to responding to original mail methods' do
      expect(Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).respond_to?(:subject)).to eq true
    end

    it 'does not admit to responding to non-existent methods' do
      expect(Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).respond_to?(:definitely_not_a_method)).to eq false
    end
  end

  describe "when setting a custom argument serializer" do
    before :all do
      @old_serializer = Resque::Mailer.argument_serializer
      Resque::Mailer.argument_serializer = TestSerializer
    end
    after :all do
      Resque::Mailer.argument_serializer = @old_serializer
    end

    it "is set" do
      expect(Resque::Mailer.argument_serializer).to eq(TestSerializer)
    end

    it "serializes the arguments with the custom serializer" do
      allow(TestSerializer).to receive(:serialize)
      expect(TestSerializer).to receive(:serialize)
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver
    end

    it "deserializes the arguments with the custom serializer" do
      allow(TestSerializer).to receive(:deserialize)
      expect(TestSerializer).to receive(:deserialize)
      Rails3Mailer.perform(:test_mail, Resque::Mailer.argument_serializer.serialize(Rails3Mailer::MAIL_PARAMS))
    end
  end
end
