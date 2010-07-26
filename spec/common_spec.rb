require File.join(File.expand_path(File.dirname(__FILE__)), 'spec_helper')

class CommonMailer
  include Resque::Mailer
end

describe Resque::Mailer do
  describe ".queue" do
    context "when not changed" do
      it "should return 'mailer'" do
        CommonMailer.queue.should == "mailer"
      end
    end

    context "when changed" do
      before do
        @my_default_queue = "foobar"
        Resque::Mailer.should_receive(:default_queue_name).and_return(@my_default_queue)
      end

      it "should return proper queue name" do
        CommonMailer.queue.should == @my_default_queue
      end
    end
  end
end
