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
        order = orders(:hitobito_demo)

        serialized = Api::V1::OrderSerializer.new(order).serializable_hash

        expected = {
          data: {
            id: '295265289',
            type: :order,
            attributes: {
              crm_key: nil,
              name: 'Demo',
              shortname: 'DEM',
              description: nil,
              closed: false,
              kind: 'Projekt',
              status: 'In Bearbeitung',
              department_name: 'devtwo',
              department_shortname: 'D2',
              contract: nil,
              billing_address: nil,
              client_name: 'Puzzle',
              client_shortname: 'PITC',
              comments: [],
              order_team_members: [
                {
                  employee_id: 5,
                  employee_name: 'Neverends John',
                  employee_shortname: 'JN',
                  comment: 'Worker bee'
                }
              ],
              invoices: []
            },
            relationships: {
              responsible: { data: { id: '8', type: :employee } },
              team_members: { data: [{ id: '5', type: :employee }] },
              additional_crm_orders: { data: [] }
            }
          }
        }

        assert_equal expected, serialized
      end
    end
  end
end
