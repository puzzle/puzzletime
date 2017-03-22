module Employees
  class LogController < ApplicationController

    before_action :authorize_action

    def index
      @versions = PaperTrail::Version.where(item_id: entry.id, item_type: Employee.sti_name)
                                     .reorder('created_at DESC, id DESC')
                                     .includes(:item)
                                     .page(params[:page])
    end

    private

    def entry
      @employee ||= Employee.find(params[:id])
    end

    def authorize_action
      authorize!(:log, entry)
    end

  end
end
