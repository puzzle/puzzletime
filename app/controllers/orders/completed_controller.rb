# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Orders
  class CompletedController < CrudController
    include Completable

    self.permitted_attrs = [:completed_at]
    self.completable_attr = :completed_at

    class << self
      def model_class
        Order
      end
    end

    private

    def entry
      @order = @entry ||= model_scope.find(params[:order_id])
    end

    def authorize
      authorize!(:update_completed, entry)
    end
  end
end
