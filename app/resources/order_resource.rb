# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Mirrors OrdersController. Everybody reads every order; Ability decides who writes (management, or the responsible
# of the order).
#
# The graph around an order is written as sideposts: `work_item` (name, shortname, description, parent_id),
# `order_team_members`, `order_contacts`, `additional_crm_orders`. completed_at/committed_at have their own routes
# (Api::V2::OrderOperationsController).
class OrderResource < ApplicationResource
  include AbilityScoped

  model Order

  # Also served from the custom routes of Api::V2::OrderOperationsController.
  self.validate_requests = false

  # Only employees have a department and are responsible (OrdersController#build_entry).
  DEFAULTS = { department_id: :department_id, responsible_id: :id }.freeze

  attribute :crm_key, :string
  attribute :kind_id, :integer
  attribute :department_id, :integer
  attribute :responsible_id, :integer
  attribute :status_id, :integer

  attribute :work_item_id, :integer, writable: false
  attribute :contract_id, :integer, writable: false
  attribute :billing_address_id, :integer, writable: false
  attribute :completed_at, :date, writable: false
  attribute :committed_at, :date, writable: false
  attribute :closed_at, :date, writable: false
  attribute :major_risk_value, :integer, writable: false
  attribute :major_chance_value, :integer, writable: false

  %i[name shortname].each do |delegated|
    attribute delegated, :string, writable: false, filterable: false, sortable: false do
      @object.public_send(delegated)
    end
  end

  belongs_to :work_item, link: false
  belongs_to :contract, link: false
  has_many :order_team_members, link: false
  has_many :order_contacts, link: false
  has_many :additional_crm_orders, link: false
  has_many :comments, resource: OrderCommentResource, link: false
  has_many :order_uncertainties
  has_many :order_risks
  has_many :order_chances
  has_many :targets, resource: OrderTargetResource, link: false
  has_many :invoices

  def base_scope
    super.list
  end

  before_attributes only: [:create] do |attributes|
    user = context.current_user
    DEFAULTS.each { |attribute, source| attributes[attribute] ||= user.public_send(source) } if user.is_a?(Employee)
  end

  # Checks the HTML controller makes with the order's parent. Errors added here fail the request (422); saving
  # is skipped, which rolls the sideposted work item back.
  def save(model, meta = nil)
    check_work_item(model)
    model.errors.any? ? model : super
  end

  private

  # The parent (a client, or a category below one) is not allowed to change; neither is the work item itself.
  def check_work_item(model)
    item = model.work_item
    return unless item

    if model.persisted?
      model.errors.add(:work_item_id, 'kann nicht geändert werden') if model.work_item_id_changed?
    elsif !valid_parent?(item.parent)
      model.errors.add(:'work_item.parent_id', 'muss ein Kunde oder eine Kategorie eines Kunden sein')
    end
  end

  def valid_parent?(parent)
    parent.present? && parent.with_ancestors.any?(&:client) && parent.order.blank? && parent.accounting_post.blank?
  end
end
