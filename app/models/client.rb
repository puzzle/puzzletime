# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Client < ActiveRecord::Base
  
  has_many :projects

  validates_presence_of :name, :contact
  validates_uniqueness_of :name
end
