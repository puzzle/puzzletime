# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Employees
  class WorktimesCommitController < CrudController

    include Completable

    self.permitted_attrs = [:committed_worktimes_at]
    self.completable_attr = :committed_worktimes_at

    class << self
      def model_class
        Employee
      end
    end

    private

    def entry
      @employee ||= model_scope.find(params[:employee_id])
    end

    def authorize
      authorize!(:update_committed_worktimes, entry)
    end

  end
end
