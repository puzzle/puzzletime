# frozen_string_literal: true

module Crm
  module Odoo
    class Partner < Base
      self.model = 'res.partner'
      self.parameters = [['is_company', '=', false]].freeze
    end
  end
end
