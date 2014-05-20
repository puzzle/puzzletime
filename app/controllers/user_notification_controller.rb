# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class UserNotificationController < ManageController

  GROUP_KEY = 'noti'

  def edit_fields
    [[:date_from, 'Startdatum'], [:date_to, 'Enddatum'], [:message, 'Nachricht']]
  end

end
