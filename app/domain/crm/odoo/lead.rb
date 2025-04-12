# frozen_string_literal: true

module Crm
  class Odoo
    class Lead < Base
      self.model = 'crm.lead'
      self.attributes = %i[id name partner_id active]
    end
  end
end
