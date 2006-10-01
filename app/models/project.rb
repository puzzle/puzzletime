# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base
  
  has_many :projectmemberships, :dependent => true
  has_many :employees, :through => :projectmemberships
  belongs_to :client
  has_many :worktimes
  
  validates_presence_of :name, :description, :client_id
  validates_uniqueness_of :name
end
