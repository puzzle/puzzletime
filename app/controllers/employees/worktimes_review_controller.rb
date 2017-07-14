module Employees
  class WorktimesReviewController < CrudController

    include Completable

    self.permitted_attrs = [:reviewed_worktimes_at]
    self.completable_attr = :reviewed_worktimes_at

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
      authorize!(:update_reviewed_worktimes, entry)
    end

  end
end
