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
