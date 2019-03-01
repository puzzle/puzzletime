module Api
  class BaseModel
    attr_reader :decorated_instance, :attributes

    class_attribute :attribute_definitions, instance_accessor: false, default: []

    def initialize(decorated_instance)
      @decorated_instance = decorated_instance
    end

    def self.decorated_model
      name.demodulize.constantize
    end

    def self.attribute(name, type, &block)
      attribute_definitions << Attribute.new(name, type, block)
      define_method(name) do
        if block_given?
          decorated_instance.instance_eval(&block)
        else
          decorated_instance.send(name)
        end
      end
    end

    # def self.relation(name, type, &block)
    #   define_method(name) do
    #     yield
    #   end
    #
    #   if
    # end

    attribute :id, :integer
  end
end