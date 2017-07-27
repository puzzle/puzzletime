#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module HolidayHelper
  def regular_holiday_string
    dates = Settings.regular_holidays.collect do |day|
      "#{day[0]}. #{I18n.t(:'date.month_names')[day[1]]}"
    end
    dates.join(', ')
  end
end
