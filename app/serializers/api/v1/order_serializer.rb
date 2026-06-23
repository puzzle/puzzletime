# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class OrderSerializer < ApiSerializer
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

      belongs_to :responsible, serializer: :employee, record_type: :employee
      has_many :team_members, serializer: :employee, record_type: :employee
      has_many :additional_crm_orders

      # -----v Attempt to solve it propperly v----
      # attribute :crm_key
      #
      # # attribute annotations for the generated api docs
      # annotate_attributes :crm_key
      #
      # belongs_to :work_item
      #
      # belongs_to :billing_address
      # belongs_to :contract
      # belongs_to :department
      # belongs_to :kind
      # belongs_to :status
      #
      # belongs_to :responsible, record_type: :employee, serializer: :employee
      #
      # # belongs_to :client do |order|
      # #   order.client
      # # end
      #
      # has_many :additional_crm_orders
      # has_many :invoices
      # has_many :order_chances
      # has_many :order_risks
      # has_many :order_team_members
      # has_many :order_uncertainties
      #
      # has_many :comments, record_type: :order_comment
      # has_many :contacts, record_type: :order_contact
      # has_many :targets, record_type: :order_target

      # has_many :accounting_posts

      # has_many :accounting_posts do |order|
      #   order.accounting_posts
      # end
    end
  end
end
