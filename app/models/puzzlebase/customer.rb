# encoding: utf-8

class Puzzlebase::Customer < Puzzlebase::Base
  has_many :customer_projects,
           foreign_key: 'FK_CUSTOMER'
  has_many :projects,
           -> { where('FK_PROJECT IS NULL') },
           through: :customer_projects,
           foreign_key: 'FK_CUSTOMER'

  MAPS_TO = ::Client
  MAPPINGS = { shortname: :S_CUSTOMER,
               name: :S_DESCRIPTION }
  FIND_OPTIONS = { select: 'DISTINCT TBL_CUSTOMER.*',
                   joins: :customer_projects,
                   conditions: ['TBL_CUSTOMER_PROJECT.B_SYNCTOPUZZLETIME'] }

end

class Client < ActiveRecord::Base
  def debug_string
    "#{shortname}: #{name}"
  end
end
