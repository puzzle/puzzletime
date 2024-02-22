# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Orders
  class CommittedController < CrudController
    include Completable

    self.permitted_attrs = [:committed_at]
    self.completable_attr = :committed_at

    class << self
      def model_class
        Order
      end
    end

    private

    def entry
      @order ||= model_scope.find(params[:order_id])
    end

    def authorize
      authorize!(:update_committed, entry)
    end
  end
end
