module Resque
  module Mailer
    module ClassMethods

      def current_env
        RAILS_ENV
      end

      def method_missing(method_name, *args)
        return super if environment_excluded?

        case method_name.id2name
        when /^deliver_([_a-z]\w*)\!/ then super(method_name, *args)
        when /^deliver_([_a-z]\w*)/ then ::Resque.enqueue(self, "#{method_name}!", *args)
        else super(method_name, *args)
        end
      end

      def perform(cmd, *args)
        send(cmd, *args)
      end

    end
  end
end
