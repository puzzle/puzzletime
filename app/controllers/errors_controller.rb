# encoding: utf-8

# Used to generate static error pages with the application layout:
# RAILS_GROUPS=assets rails generate error_page {status}
class ErrorsController < ActionController::Base
  layout 'application'
end
