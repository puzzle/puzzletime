# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Masterdata < ActiveRecord::Base
  @@data = nil
  def self.instance
    if @@data == nil
      @@data = Masterdata.find(:first)
    end
    @@data
   end
end
