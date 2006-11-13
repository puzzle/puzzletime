# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Client < ActiveRecord::Base

  # All dependencies between the models are listed below.
  has_many :projects, :order => "name"
  
  # Validation helpers.
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def self.list(id = nil)
    if id != nil
      find(id).to_a
    else  
      find(:all, :order => "name")  
    end  
  end
  
  def label
    name
  end
 
  def subdivisionRef
    0
  end
  
  def detailFor(time)
    time.employee.shortname
  end
end
