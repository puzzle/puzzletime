# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Projectmembership < ActiveRecord::Base

  belongs_to :employee
  belongs_to :project
  
  def self.is_projectmanagement(user)
    if Projectmembership.find(:first, :conditions =>["employee_id = ? AND projectmanagement IS TRUE", user.id])
      true
    else
      false
    end
  end
end
