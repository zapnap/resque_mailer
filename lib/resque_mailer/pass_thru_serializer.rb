module Resque
  module Mailer

    # Simple serializer for Resque arguments
    # New serializers need only implement the self.serialize(*args) and self.deserialize(data)
    # * self.serialize(*args) should return the arguments serialized as an object
    # * self.deserialize(data) should take the serialized object as its only argument and return the array of arguments

    class PassThruSerializer
      def self.serialize(*args)
        args
      end

      def self.deserialize(data)
        data
      end
    end
  end
end