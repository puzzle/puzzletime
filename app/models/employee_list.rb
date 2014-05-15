# encoding: utf-8
# == Schema Information
#
# Table name: employee_lists
#
#  id          :integer          not null, primary key
#  employee_id :integer          not null
#  title       :string(255)      not null
#  created_at  :datetime
#  updated_at  :datetime
#


class EmployeeList < ActiveRecord::Base

  has_and_belongs_to_many :employees

  validates_presence_of :title, message: 'Name der Mitarbeiterliste fehlt.'

end
