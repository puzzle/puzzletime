# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Employment < ActiveRecord::Base
  
  # All dependencies between the models are listed below.
  validates_presence_of :percent
  belongs_to :employee
  
  def period
    return Period.new(start_date, end_date)
  end
  
  def percentFactor
    percent / 100.0
  end
  
  def holidays
    round2Decimals(period.length / 365.25 * Masterdata.instance.vacations_year * percentFactor)
  end 
  
  def musttime
    period.musttime * percentFactor
  end
  
private

  def round2Decimals(number)  
    (number * 100).round / 100.0
  end
  
end