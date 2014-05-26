# encoding: utf-8

class Puzzlebase::Unit < Puzzlebase::Base

  has_many :projects,
           foreign_key: 'FK_UNIT'

  MAPS_TO = ::Department
  MAPPINGS = { shortname: :S_UNIT,
               name: :S_DESCRIPTION }

end
