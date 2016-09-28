module Plannings
  class DepartmentsController < ListController

    self.search_columns = %w(name shortname)

  end
end