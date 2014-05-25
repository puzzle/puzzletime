# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class UserNotificationsController < ManageController

  self.permitted_attrs = [:date_from, :date_to, :message]

end
