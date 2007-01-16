# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base
  
  include Evaluatable

  # All dependencies between the models are listed below.
  has_many :projectmemberships, :dependent => true, :finder_sql => 
    'SELECT m.* FROM projectmemberships m, employees e ' +
    'WHERE m.project_id = #{id} AND e.id = m.employee_id ' +
    'ORDER BY e.lastname, e.firstname'
  has_many :employees, :through => :projectmemberships, :order => "lastname, firstname"
  belongs_to :client
  has_many :worktimes, :dependent => true
  
  # Validation helpers.  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def self.list
    self.find(:all, :order => 'client_id, name')
  end
  
  def label_verbose
    client.name + ' - ' + name
  end

end
