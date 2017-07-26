# encoding: utf-8

class UserNotificationsController < ManageController
  self.permitted_attrs = [:date_from, :date_to, :message]
end
