# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

require "digest/sha1"

class Employee < ActiveRecord::Base

  has_many :employments 
  has_many :projectmemberships, :dependent => true
  has_many :projects, :through => :projectmemberships
  has_many :worktimes
  
  attr_accessor :pwd
  
  validates_presence_of :firstname, :lastname, :shortname, :email, :phone
  validates_presence_of :pwd, :on => :create
  validates_uniqueness_of :shortname 
  
  def before_create
    self.passwd = Employee.encode(self.pwd)
  end
  
  def after_create
    @pwd = nil
  end
  
  def self.login(shortname, pwd)
    passwd = encode(pwd)
    find(:first,
         :conditions =>["shortname = ? and passwd = ?",
                         shortname, passwd])
  end
  
  def self.checkpwd(id, pwd)
    passwd = encode(pwd)
    nil != find(:first,
         :conditions =>["id = ? and passwd = ?",
                         id, passwd])
  end
  
  def updatepwd(pwd)
    hashed_pwd = Employee.encode(pwd)
    update_attributes(:passwd => hashed_pwd)
  end
  
  private
  def self.encode(pwd)
    Digest::SHA1.hexdigest(pwd) 
  end
end
