# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Mirrors AccountingPostsController: every employee reads all posts, writes are authorized per instance by Ability
# and go through AccountingPost#attach_work_item. Besides its columns a write takes `order_id` (create only),
# `book_on_order` and `work_item_attributes` ({name, shortname, description}) for the work item.
class AccountingPostResource < ApplicationResource
  model AccountingPost

  # `GET /orders/:id/accounting_posts` is served by this resource too, a path with a parameter that
  # secondary_endpoint cannot declare.
  self.validate_requests = false

  WORK_ITEM_KEYS = %i[name shortname description].freeze
  NON_COLUMNS = %i[order_id book_on_order work_item_attributes].freeze

  attribute :closed, :boolean
  attribute :offered_hours, :float
  attribute :offered_rate, :big_decimal
  attribute :offered_total, :big_decimal
  attribute :remaining_hours, :integer
  attribute :portfolio_item_id, :integer
  attribute :service_id, :integer
  attribute :billable, :boolean
  attribute :description_required, :boolean
  attribute :ticket_required, :boolean
  attribute :from_to_times_required, :boolean
  attribute :meal_compensation, :boolean
  attribute :billing_reminder_active, :boolean
  attribute :work_item_id, :integer, writable: false

  attribute :order_id, :integer, readable: false, sortable: false
  attribute :book_on_order, :boolean, readable: false, filterable: false, sortable: false
  attribute :work_item_attributes, :hash, readable: false, filterable: false, sortable: false

  # Posts at or below the work item of an order.
  filter :order_id do
    eq do |scope, order_ids|
      scope.joins(:work_item).where('work_items.path_ids && ARRAY[?]::integer[]',
                                    Order.where(id: order_ids).pluck(:work_item_id)) # rubocop:disable Rails/PluckInWhere -- bound into ARRAY[?]
    end
  end

  def base_scope
    current_user.is_a?(Employee) ? AccountingPost.all : AccountingPost.none
  end

  # Keeps the non-column attributes for #save. A new post starts below the order's work item so Ability can
  # tell whose order it is (AccountingPostsController#build_entry).
  def assign_attributes(model, attributes)
    @book_on_order = attributes[:book_on_order] == true
    @work_item_attributes = attributes[:work_item_attributes].to_h.symbolize_keys.slice(*WORK_ITEM_KEYS)
    super(model, attributes.except(*NON_COLUMNS))
    return unless model.new_record?

    @order = Order.find(attributes[:order_id])
    model.build_work_item(parent_id: @order.work_item_id)
  end

  # attach_work_item persists a work item before the post is validated (as in the HTML controller): when the post
  # is rejected that work item is removed again, so no orphan stays behind.
  def save(model, meta = nil)
    original_id = model.work_item_id
    order = @order || model.order
    model.attach_work_item(order, @work_item_attributes, @book_on_order)
    super.tap { |post| discard_work_item(post, order, original_id) if post.errors.any? }
  end

  private

  def discard_work_item(post, order, original_id)
    item = post.work_item
    return unless item&.persisted? && [original_id, order.work_item_id].exclude?(item.id)

    item.destroy
  end
end
