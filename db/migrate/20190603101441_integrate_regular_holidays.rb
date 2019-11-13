class IntegrateRegularHolidays < ActiveRecord::Migration[5.2]
  def up
    return unless Settings.regular_holidays&.any?
    return unless Holiday.exists?

    say 'Found regular holidays in the settings'

    min_holiday = Holiday.minimum(:holiday_date).year
    max_holiday = Holiday.maximum(:holiday_date).year

    say_with_time('Putting the regular holidays into the holidays table...') do
      Settings.regular_holidays.each do |day, month|
        (min_holiday..max_holiday).each do |year|
          holiday = Date.new(year, month, day)
          Holiday.find_or_create_by!(holiday_date: holiday, musthours_day: 0)
        end
      end
    end

    say '************************** Manual Step *************************'
    say '* Please remove the regular holidays from the config file now. *'
    say '****************************************************************'
  end

  def down
    say '************************** Manual Step *************************'
    say '* Regular holidays will not be restored, you have to delete    *'
    say '* them manually and put them into the Settings file.           *'
    say '*                                                              *'
    say '* Syntax:                                                      *'
    say '* # Array of holidays with a fixed date. [day, month]          *'
    say '* regular_holidays:                                            *'
    say '*   -                                                          *'
    say '*     - 1                                                      *'
    say '*     - 1                                                      *'
    say '*                                                              *'
    say '****************************************************************'
  end
end
