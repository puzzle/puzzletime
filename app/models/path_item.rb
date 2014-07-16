# == Schema Information
#
# Table name: path_items
#
#  id              :integer          not null, primary key
#  parent_id       :integer
#  name            :string(255)      not null
#  shortname       :string(255)      not null
#  path_ids        :integer          is an Array
#  path_shortnames :string(255)
#  path_names      :string(2047)
#  leaf            :boolean          default(TRUE), not null
#

class PathItem < ActiveRecord::Base

  belongs_to :parent

  has_one :client
  has_one :order
  has_one :accounting_post

end
