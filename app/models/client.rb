# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Client < ActiveRecord::Base

  # All dependencies between the models are listed below
  has_many :projects
  
  # Validation helpers
  validates_presence_of :name, :contact
  validates_uniqueness_of :name
end
