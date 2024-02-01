#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class AccountingPostsController < CrudController
  self.nesting = [Order]

  self.permitted_attrs = [:closed, :offered_hours, :offered_rate, :offered_total,
                          :remaining_hours, :portfolio_item_id, :service_id, :billable,
                          :description_required, :ticket_required, :from_to_times_required,
                          :meal_compensation,
                          { work_item_attributes: %i[name shortname description] }]

  helper_method :order

  def index
    @cockpit = Order::Cockpit.new(parent)
  end

  private

  def find_entry
    super
  rescue ActiveRecord::RecordNotFound
    # happens when changing order in top dropdown while editing accounting post.
    redirect_to order_accounting_posts_path(order)
    AccountingPost.new
  end

  def build_entry
    super.tap { |p| p.build_work_item(parent_id: order.work_item_id) }
  end

  def assign_attributes
    entry.attributes = model_params.except(:work_item_attributes)
    entry.attach_work_item(order, model_params[:work_item_attributes], book_on_order?)
  end

  def book_on_order?
    params[:book_on_order].to_s == 'true'
  end

  def index_path
    order_accounting_posts_path(parent)
  end

  def order
    parent
  end
end
