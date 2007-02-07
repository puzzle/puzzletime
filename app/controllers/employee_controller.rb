# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EmployeeController < ApplicationController

  include ManageModule

  # Checks if employee came from login or from direct url
  before_filter :authorize, :except => [:changePasswd, :updatePwd]
  before_filter :authenticate, :only => [:changePasswd, :updatePwd]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :updatePwd ],
         :redirect_to => { :controller => 'worktime', :action => 'listTime' }
  
  #Update userpwd
  def updatePwd
    if Employee.checkpwd(@user.id, params[:pwd])
      if params[:change_pwd] === params[:change_pwd_confirmation]
        @user.updatepwd(params[:change_pwd])
        flash[:notice] = 'Das Passwort wurde aktualisiert'
        redirect_to :controller =>'worktime', :action => 'listTime', :id => @user.id
      else
        flash[:notice] = 'Die Passwort Best&auml;tigung stimmt nicht mit dem Passwort &uuml;berein'
        render :controller =>'employee', :action => 'changePasswd', :id => @user.id
      end
    else
      flash[:notice] = 'Das alte Passwort ist falsch'
      render :controller =>'employee', :action => 'changePasswd', :id => @user.id
    end  
  end
  
  ##### helper methods for ManageModule ##### 
  
  def modelClass
    Employee
  end
  
  def listActions
    [['Anstellungen', 'employment', 'list'],
     ['&Uuml;berzeit', 'overtime_vacation', 'list']]
  end  
    
  def editFields    
    [[:firstname, 'Vorname'], 
     [:lastname, 'Nachname'],
     [:shortname, 'Kürzel'],
     [:email, 'Email'],
     [:phone, 'Telefon'],
     [:initial_vacation_days, 'Anfängliche Ferien'],
     [:management, 'GL']]    
  end
  
  def listFields
    [[:lastname, 'Nachname'],
     [:firstname, 'Vorname'], 
     [:shortname, 'Kürzel'],
     [:current_percent, 'Prozent'],
     [:management, 'GL']]
  end
  
  def formatColumn(attribute, value)
    return (value ? value.to_s + ' %' : 'keine') if :current_percent == attribute
    super  attribute, value 
  end 

end
