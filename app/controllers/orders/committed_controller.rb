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