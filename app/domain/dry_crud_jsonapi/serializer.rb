module DryCrudJsonapi
  class Serializer
    attr_reader :model_class, :serializer_class, :define_conditionals

    def initialize(model_class)
      @model_class = model_class.to_s.constantize
      @serializer_class = Class.new(JSONAPI::Serializable::Resource)
      @serializer_class.send :extend, JSONAPI::Serializable::Resource::ConditionalFields

      @define_conditionals = {
        vmware_license:  { if: -> { @current_user.license? } },
        discoverer:      { if: -> { @object.try(:discoverer_id).present? } }
      }
    end

    def build
      define_type
      define_attributes
      define_link_to_self
      define_has_one_relations
      define_belongs_to_relations
      define_has_many_relations(:through)
      define_has_many_relations(:has_many)

      serializer_class
    end

    private

    def define_type
      serializer_class.type model_class.model_name.param_key
    end

    def define_attributes
      attribute_names.each do |name|
        define_conditional(:attribute, name)
      end
    end

    def define_link_to_self
      serializer_class.link(:self) do
        @controller.rescued_polymorphic_path(@object)
      end
    end

    def define_has_one_relations
      reflections(for_type(:has_one)).each do |reflection|
        define_conditional(:has_one, reflection.name.to_s) do
          data { @object.send(reflection.name) }
        end
      end
    end

    def define_belongs_to_relations
      reflections(for_type(:belongs_to)).each do |reflection|
        define_conditional(:belongs_to, reflection.name.to_s) do
          data { @object.send(reflection.name) }
        end
      end
    end

    def define_has_many_relations(type)
      reflections(for_type(type)).each do |reflection|
        define_conditional(:has_many, reflection.name) do
          link(:related) do
            @controller.rescued_polymorphic_path([@object, reflection.name])
          end
        end
      end
    end

    def define_conditional(method, name, &block)
      condition = define_conditionals.find(->{[{}]}) { |key, _| name.to_s =~ /#{key}/ }.last
      serializer_class.send(method, name, **condition, &block)
    end

    def attribute_names
      model_class.column_names.reject do |column|
        %w[passwd].include?(column)
      end
    end

    def for_type(type)
      "ActiveRecord::Reflection::#{type.to_s.camelcase}Reflection".constantize
    end

    def reflections(type)
      @reflections ||= {}
      @reflections[type] ||= model_class.reflect_on_all_associations.select do |reflection|
        reflection.is_a?(type)
      end
    end
  end
end
