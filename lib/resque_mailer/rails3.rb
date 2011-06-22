module Resque
  module Mailer
    module ClassMethods

      def current_env
        ::Rails.env
      end

      def method_missing(method_name, *args)
        return super if environment_excluded?

        if action_methods.include?(method_name.to_s)
          mailer_class = self
          resque = self.resque

          super.tap do |resque_mail|
            resque_mail.class_eval do
              define_method(:deliver) do
                resque.enqueue(mailer_class, method_name, *args)
                self
              end
            end
          end
        else
          super
        end
      end

      def perform(action, *args)
        self.send(:new, action, *args).message.deliver!
      end

    end
  end
end
