# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V1
    class OrderSerializerTest < ActiveSupport::TestCase
      test '#serializable_hash' do
        order = orders(:api_order_two)

        serialized = Api::V1::OrderSerializer.new(order).serializable_hash

        expected = {
          data: {
            id: order.id.to_s,
            type: :order,
            attributes: {
              crm_key: nil,
              name: 'Apinexus Two',
              shortname: 'APIO2',
              description: nil,
              closed: false,
              kind: 'Mandat',
              status: 'Offeriert',
              department_name: 'apidept',
              department_shortname: 'API',
              contract: nil,
              billing_address: nil,
              client_name: 'Apinexus',
              client_shortname: 'APINX',
              comments: [],
              order_team_members: [
                {
                  employee_id: 20,
                  employee_name: 'Apitest Alice',
                  employee_shortname: 'AA',
                  comment: 'Worker bee'
                }
              ],
              invoices: []
            },
            relationships: {
              responsible: { data: { id: '21', type: :employee } },
              team_members: { data: [{ id: '20', type: :employee }] },
              additional_crm_orders: { data: [] }
            }
          }
        }

        assert_equal expected, serialized
      end
    end
  end
end
