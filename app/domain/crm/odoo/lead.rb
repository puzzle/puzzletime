# frozen_string_literal: true

module Crm
  class Odoo
    class Lead < Base
      self.model = 'crm.lead'
      self.local_models = %w[Order AdditionalCrmOrder]
      self.attributes = %i[id name partner_id active]

      class_setup
    end
  end
end
