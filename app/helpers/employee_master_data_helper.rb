# encoding: utf-8

module EmployeeMasterDataHelper
  def format_year_of_service(employment)
    Time.zone.now.year - employment.year
  end
end
