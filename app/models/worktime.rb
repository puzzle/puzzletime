# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Worktime < ActiveRecord::Base

  belongs_to :absence 
  belongs_to :employee
  belongs_to :project
  
  attr_accessor :start
  attr_accessor :end
end
