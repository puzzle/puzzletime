# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Absence < ActiveRecord::Base
  
  has_many :worktimes
  VACATION_ID = 3
  
  validates_presence_of :name
  validates_uniqueness_of :name
end
