# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Worktime < ActiveRecord::Base
  
  # All dependencies between the models are listed below.
  belongs_to :absence 
  belongs_to :employee
  belongs_to :project
  
  #Accessor needed for all select*.rhtml
  attr_accessor :start
  attr_accessor :end
end
