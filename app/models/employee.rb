# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

require "digest/sha1"

class Employee < ActiveRecord::Base

  has_many :employments 
  has_many :projectmemberships, :dependent => true
  has_many :projects, :through => :projectmemberships
  has_many :worktimes
  
  attr_accessor :pwd, :change_pwd, :change_pwd_confirmation
  
  validates_presence_of :firstname, :lastname, :shortname, :email, :phone
  validates_presence_of :pwd, :on => :create
  validates_uniqueness_of :shortname 
  #validates_confirmation_of :change_pwd, :on => :update
  
  def before_create
    self.passwd = Employee.passwd(self.pwd)
  end
  
  def after_create
    @pwd = nil
  end
  
  def before_updatepwd
   self.passwd = Employee.passwd(self.change_pwd)
  end
  
  def after_updatepwd
    @change_pwd = nil
  end
  
  
  def self.login(shortname, pwd)
    passwd = passwd(pwd || "")
    find(:first,
         :conditions =>["shortname = ? and passwd = ?",
                         shortname, passwd])
  end
  
  def self.checkpwd(id, pwd)
    passwd = passwd(pwd || "")
    find(:first,
         :conditions =>["id = ? and passwd = ?",
                         id, passwd])
  end
  
  def try_to_checkpwd
     Employee.checkpwd(self.id, self.pwd)
  end
  
  def try_to_login
    Employee.login(self.shortname, self.pwd)
  end
  
  private
  def self.passwd(pwd)
    Digest::SHA1.hexdigest(pwd) 
  end
end
