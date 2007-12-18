class Department < ActiveRecord::Base

  has_many :projects, :order => 'name'

end