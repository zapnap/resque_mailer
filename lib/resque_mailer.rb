module Resque
  module Mailer
    class << self
      attr_accessor :default_queue_name
      attr_reader :excluded_environments

      def excluded_environments=(envs)
        @excluded_environments = [*envs].map { |e| e.to_sym }
      end

      def included(base)
        base.extend(ClassMethods)
      end
    end

    self.default_queue_name = "mailer"
    self.excluded_environments = [:test]

    module ClassMethods
      def current_env
        ::Rails.env
      end

      def method_missing(method_name, *args)
        return super if environment_excluded?

        if action_methods.include?(method_name.to_s)
          mailer_class = self
          super.tap do |resque_mail|
            resque_mail.class_eval do
              define_method(:deliver) do
                ::Resque.enqueue(mailer_class, method_name, *args)
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

      def environment_excluded?
        !ActionMailer::Base.perform_deliveries || excluded_environment?(current_env)
      end

      def queue
        ::Resque::Mailer.default_queue_name
      end

      def excluded_environment?(name)
        ::Resque::Mailer.excluded_environments && ::Resque::Mailer.excluded_environments.include?(name.to_sym)
      end
    end
  end
end
