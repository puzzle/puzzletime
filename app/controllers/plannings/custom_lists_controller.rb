# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Plannings
  class CustomListsController < CrudController

    self.nesting = [:plannings]
    self.permitted_attrs = [:name, :item_type, item_ids: []]
    self.search_columns = [:name]

    before_render_show :set_items
    before_render_form :load_available_items

    private

    def set_items
      @items = entry.items.list
    end

    def load_available_items
      @available_items =
        case entry.item_type
        when Employee.sti_name
          Employee.employed_ones(Period.current_year).list
        when Order.sti_name
          Order.joins(:status)
               .where(order_statuses: { closed: false })
               .list
               .reorder('work_items.path_shortnames')
        when String
          entry.item_type.constantize.list
        else
          raise ActionController::BadRequest
        end
    end

    def model_scope
      @user.custom_lists
    end

    def model_params
      super.tap do |p|
        if p[:item_type] && ![Employee, Order].map(&:sti_name).include?(p[:item_type])
          raise ActionController::BadRequest
        end
      end
    end

  end
end
