# == Schema Information
#
# Table name: work_items
#
#  id              :integer          not null, primary key
#  parent_id       :integer
#  name            :string(255)      not null
#  shortname       :string(255)      not null
#  description     :text
#  path_ids        :integer          is an Array
#  path_shortnames :string(255)
#  path_names      :string(2047)
#  leaf            :boolean          default(TRUE), not null
#  closed          :boolean          default(FALSE), not null
#

class WorkItem < ActiveRecord::Base

  acts_as_tree order: 'shortname'

  belongs_to :parent

  has_one :client
  has_one :order
  has_one :accounting_post

  has_many :worktimes,
           ->(work_item) do
             joins(:work_item).
             unscope(where: :work_item_id).
             where('worktimes.work_item_id = work_items.id AND ' \
                   "? = ANY (work_items.path_ids)", work_item.id)
           end

  scope :list, -> { order('path_shortnames') }
  scope :recordable, -> { where(leaf: true, closed: false) }

  def to_s
    name
  end

end
