# encoding: utf-8

module Reports::Revenue
  class Service < Base

    self.grouping_model = ::Service
    self.grouping_fk = :service_id

  end
end
