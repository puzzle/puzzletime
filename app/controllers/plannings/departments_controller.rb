module Plannings
  class DepartmentsController < ListController

    self.search_columns = %w(name shortname)

    private

    def authorize_class
      authorize!(:read, Planning)
    end

  end
end
