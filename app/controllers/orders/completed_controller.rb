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
      @order ||= model_scope.find(params[:order_id])
    end

    def authorize
      authorize!(:update_completed, entry)
    end

  end
end
