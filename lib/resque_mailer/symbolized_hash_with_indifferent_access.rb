require 'active_support/core_ext/hash'
require 'delegate'

module Resque
  module Mailer
    class SymbolizedHashWithIndifferentAccess < ::SimpleDelegator
      def to_hash
        super.tap(&:symbolize_keys!)
      end

      def __setobj__(obj)
        @delegate_sd_obj = obj.with_indifferent_access
      end
    end
  end
end
