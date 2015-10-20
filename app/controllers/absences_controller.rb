# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class AbsencesController < ManageController
  self.permitted_attrs = [:name, :payed, :private, :vacation]
end
