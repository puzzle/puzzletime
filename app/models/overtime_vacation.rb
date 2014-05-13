class OvertimeVacation < ActiveRecord::Base

  extend Manageable

  belongs_to :employee

  before_validation DateFormatter.new('transfer_date')

  validates_inclusion_of :hours, in: 0.001...999_999, message: 'Die Stunden müssen positiv sein'
  validates_presence_of :transfer_date, message: 'Das Datum muss angegeben werden'
  validates_presence_of :employee_id, message: 'Es muss ein Mitarbeiter angegeben werden'

  def days
    hours / 8.0
  end

  def days=(value)
    self.hours = days * 8
  end

  ##### interface methods for Manageable #####

  def label
    "die &Uuml;berzeit-Ferien Umbuchung von #{hours} Stunden am #{transfer_date.strftime(DATE_FORMAT)}"
  end

  def self.labels
    ['Die', '&Uuml;berzeit-Ferien Umbuchung', '&Uuml;berzeit-Ferien Umbuchungen']
  end

  def self.orderBy
    'transfer_date DESC'
  end

  ##### caching #####

  def transfer_date
    # cache holiday date to prevent endless string_to_date conversion
    @transfer_date ||= read_attribute(:transfer_date)
  end

  def transfer_date=(value)
    write_attribute(:transfer_date, value)
    @transfer_date = nil
  end

end
