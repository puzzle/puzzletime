# encoding: utf-8

class AbsencesController < ManageController
  self.permitted_attrs = [:name, :payed, :vacation]
end
