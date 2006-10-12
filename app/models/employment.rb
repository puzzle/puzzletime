# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Employment < ActiveRecord::Base

  validates_presence_of :percent
  belongs_to :employee
end