# frozen_string_literal: true

module Employees
  class VcardBulk
    def initialize(employees)
      @employees = employees
    end

    def render
      @employees.map { |e| Vcard.new(e).render }.join
    end
  end
end
