# frozen_string_literal: true

module Crm
  module Odoo
    class Company < Base
      self.model = 'res.partner'
      self.parameters = [['is_company', '=', true]].freeze
    end
  end
end
