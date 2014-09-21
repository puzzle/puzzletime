# encoding: UTF-8

class StatusController < ApplicationController

  skip_before_action :authenticate
  skip_authorization_check

  def index
    result = ActiveRecord::Base.connected? ? "OK" : "ERROR: Can not connect to the database"
    render text: result
  end

end
