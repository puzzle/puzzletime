# encoding: UTF-8

require 'rails_erd/domain/specialization'

module RailsERD
  class Domain
    class Specialization
      class << self
        def abstract_from_models(domain, models)
          models.select(&:abstract_class?).
            collect(&:descendants).
            flatten.
            select  { |model| domain.entity_by_name(model.name) }.
            collect do |model|
            new(domain, domain.entity_by_name(model.superclass.name), domain.entity_by_name(model.name))
          end
        end
      end
    end
  end
end
