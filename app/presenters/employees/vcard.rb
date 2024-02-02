# frozen_string_literal: true

module Employees
  class Vcard
    TEMPLATE_FILE = File.expand_path('vcard.vcf.haml', __dir__)

    attr_reader :employee, :include

    def initialize(employee, include: nil)
      @employee = employee
      @include = include
    end

    def render
      Haml::Template.new(TEMPLATE_FILE).render(nil, employee: self)
    end

    def method_missing(method_name, *)
      return employee.send(method_name, *) if include.blank? || include.include?(method_name)

      nil
    end

    def respond_to_missing?(method_name, include_private = false)
      return employee.respond_to?(method_name, include_private)
      super
    end

    private

    def template
      @template ||= File.read(TEMPLATE_FILE)
    end
  end
end
