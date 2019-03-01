module Api
  class BaseModel
    class Attribute
      attr_reader :name, :type, :block

      def initialize(name, type, block)
        @name = name.to_sym
        @type = type
        @block = block
      end

      def value(model)
        model.instance_eval(&block)
      end

      def to_s
        name.to_s
      end
    end
  end
end