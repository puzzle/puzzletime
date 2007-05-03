# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class UserNotification < ActiveRecord::Base

  extend Manageable
  
  # Validation helpers
  before_validation DateFormatter.new('date_from', 'date_to')
  validates_presence_of :date_from, :message => "Eine Startdatum muss angegeben werden"
  validates_presence_of :message, :message => "Eine Nachricht muss angegeben werden"
    
  ##### interface methods for Manageable #####

  def label
    "die Nachricht '#{message}'"
  end

  def self.labels
    ['Die', 'Nachricht', 'Nachrichten']
  end

  def self.orderBy
    'date_from DESC, date_to DESC'
  end

  def validate
    errors.add(:date_to, "Enddatum muss nach Startdatum sein.") if date_from > date_to
  end
  
  def self.list_during(period=nil)
    period ||= Period.currentWeek
    list(:conditions => ['date_from BETWEEN ? AND ? OR date_to BETWEEN ? AND ?', 
                          period.startDate, period.endDate, 
                          period.startDate, period.endDate],
         :order => 'date_from')
  end
end