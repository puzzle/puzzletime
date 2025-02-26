# frozen_string_literal: true

module Crm
  class Odoo
    class Lead < Base
      self.model = 'crm.lead'
      # self.options = {}.freeze
      self.options = {fields: %i[id name partner_id]}.freeze
    end
  end
end
