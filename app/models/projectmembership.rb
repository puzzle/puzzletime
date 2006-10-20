# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Projectmembership < ActiveRecord::Base

  # All dependencies between the models are listed below
  belongs_to :employee
  belongs_to :project
  
  # Checks if user is in projectmanagement
  def self.is_projectmanagement(user)
    if Projectmembership.find(:first, :conditions =>["employee_id = ? AND projectmanagement IS TRUE", user.id])
      true
    else
      false
    end
  end
end
