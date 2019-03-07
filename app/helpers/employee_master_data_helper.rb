#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module EmployeeMasterDataHelper
  def format_year_of_service(employment_date)
    ((Date.current - employment_date) / 365).floor
  end

  def format_nationalities(employee)
    return unless employee.nationalities.present?

    employee.nationalities.map do |country_code|
      country = ISO3166::Country[country_code]
      country.translations[I18n.locale.to_s] || country.name
    end.join(', ')
  end
end
