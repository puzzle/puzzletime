# encoding: utf-8

class EmployeeList < ActiveRecord::Base

  has_and_belongs_to_many :employees

  validates_presence_of :title, message: 'Name der Mitarbeiterliste fehlt.'

end
