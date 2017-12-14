require 'active_support/core_ext/hash'
require 'delegate'

module Resque
  module Mailer
    class SymbolizedHashWithIndifferentAccess < DelegateClass(HashWithIndifferentAccess)
      def initialize(obj= {})
        super obj.with_indifferent_access
      end

      def to_hash
        symbolize_keys
      end
    end
  end
end
