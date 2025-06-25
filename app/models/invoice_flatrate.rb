# frozen_string_literal: true

class InvoiceFlatrate < ApplicationRecord
  belongs_to :flatrate
  belongs_to :invoice
end
