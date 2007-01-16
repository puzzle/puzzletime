class DatebocksController < ApplicationController #:nodoc:
	def index
	end
	
	def help
		render :partial => 'datebocks/help'
	end
end