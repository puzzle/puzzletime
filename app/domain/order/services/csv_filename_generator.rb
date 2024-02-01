#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Order::Services
  class CsvFilenameGenerator
    attr_reader :order, :params

    def initialize(order, params = {})
      @order = order
      @params = params
    end

    def filename
      ['puzzletime',
       accounting_post_shortnames || order_shortnames,
       employee_shortname,
       ticket,
       billable]
        .compact
        .join('-') +
        '.csv'
    end

    private

    def order_shortnames
      order.work_item.path_shortnames
    end

    def accounting_post_shortnames
      return unless params[:work_item_id].present?

      WorkItem.find(params[:work_item_id]).path_shortnames
    end

    def employee_shortname
      return unless params[:employee_id].present?

      Employee.find(params[:employee_id]).shortname
    end

    def billable
      "billable_#{params[:billable]}" if params[:billable].present?
    end

    def ticket
      "ticket_#{params[:ticket]}" if params[:ticket].present?
    end
  end
end
