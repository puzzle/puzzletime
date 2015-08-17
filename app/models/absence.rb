# encoding: utf-8
# == Schema Information
#
# Table name: absences
#
#  id       :integer          not null, primary key
#  name     :string(255)      not null
#  payed    :boolean          default(FALSE)
#  private  :boolean          default(FALSE)
#  vacation :boolean          default(FALSE), not null
#

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Absence < ActiveRecord::Base

  include Evaluatable

  # All dependencies between the models are listed below
  has_many :worktimes
  has_many :employees, through: :worktimes

  protect_if :worktimes, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Arbeitszeiten zugeordnet sind'

  # Validation helpers
  validates_by_schema
  validates :name, uniqueness: true

  scope :list, -> { order(:name) }


  def to_s
    name
  end

end
