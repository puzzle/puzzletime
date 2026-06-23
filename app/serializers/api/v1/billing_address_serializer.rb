# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class BillingAddressSerializer < ApiSerializer
      attributes :supplement,
                 :street,
                 :zip_code,
                 :town,
                 :country,
                 :invoicing_key

      annotate_attributes :supplement,
                          :street,
                          :zip_code,
                          :town,
                          :country,
                          :invoicing_key

      belongs_to :client
      belongs_to :contact

      has_many :orders
      has_many :invoices
    end
  end
end
