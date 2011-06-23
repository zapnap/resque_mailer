module Resque
  module Mailer

    class Rails3MailerProxy
      def initialize(mailer_class, action, *args)
        @mailer_class = mailer_class
        @action = action
        @args = args
      end

      def deliver
        ::Resque.enqueue(@mailer_class, @action, *@args)
      end

      def deliver!
        original_message.deliver
      end

      def respond_to?(method, *args)
        super || original_message.respond_to?(method, *args)
      end

      def method_missing(method_name, *args)
        original_message.send(method_name, *args)
      end

      protected

      def original_message
        @original_message ||= @mailer_class.send(:new, @action, *@args).message
      end
    end

    module ClassMethods

      def current_env
        ::Rails.env
      end

      def method_missing(method_name, *args)
        return super if environment_excluded?

        if action_methods.include?(method_name.to_s)
          Rails3MailerProxy.new(self, method_name, *args)
        else
          super
        end
      end

      def perform(action, *args)
        Rails3MailerProxy.new(self, action, *args).deliver!
      end

    end
  end
end
