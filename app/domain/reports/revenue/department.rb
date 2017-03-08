# encoding: utf-8

module Reports::Revenue
  class Department < Base

    self.grouping_model = ::Department
    self.grouping_fk = :department_id

  end
end
