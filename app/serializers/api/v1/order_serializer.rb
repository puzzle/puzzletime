# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class OrderSerializer < ApiSerializer
      belongs_to :responsible, serializer: :employee, record_type: :employee
      has_many :team_members, serializer: :employee, record_type: :employee
      has_many :additional_crm_orders

      attributes :crm_key, :name, :shortname, :description

      attribute :closed do |order|
        order.work_item.closed
      end

      attribute :kind do |order|
        order.kind&.name
      end

      attribute :status do |order|
        order.status&.name
      end

      attribute :department_name do |order|
        order.department&.name
      end

      attribute :department_shortname do |order|
        order.department&.shortname
      end

      attribute :contract do |order|
        order.contract&.attributes
      end

      attribute :billing_address do |order|
        order.billing_address&.attributes
      end

      attribute :client_name do |order|
        order.client.name
      end

      attribute :client_shortname do |order|
        order.client.shortname
      end

      attribute :comments do |order|
        order.comments.pluck(:text)
      end

      attribute :order_team_members do |order|
        order.order_team_members.map do |otm|
          {
            employee_id: otm.employee.id,
            employee_name: otm.employee.to_s,
            employee_shortname: otm.employee.shortname,
            comment: otm.comment
          }
        end
      end

      attribute :invoices do |order|
        order.invoices.map(&:attributes)
      end

      # attribute annotations for the generated api docs

      annotate_attributes :crm_key, :name, :shortname, :description, :kind, :status,
                          :department_name, :department_shortname, :client_name, :client_shortname,
                          type: :string

      annotate_attribute :closed,
                         type: :boolean,
                         description: 'Whether the order’s work item is closed'

      annotate_attribute :comments,
                         type: :array,
                         description: 'The texts of all comments on the order',
                         items: {
                           type: :string
                         }

      annotate_attribute :contract,
                         description: 'The contract’s attributes, or null if none is set',
                         **object_schema(Contract)

      annotate_attribute :billing_address,
                         description: 'The billing address’ attributes, or null if none is set',
                         **object_schema(BillingAddress)

      annotate_attribute :order_team_members,
                         type: :array,
                         items: {
                           type: :object,
                           properties: {
                             employee_id: { type: :integer },
                             employee_name: { type: :string },
                             employee_shortname: { type: :string },
                             comment: { type: :string }
                           }
                         }

      annotate_attribute :invoices,
                         type: :array,
                         description: 'The attributes of each invoice on the order',
                         items: object_schema(Invoice)
    end
  end
end
