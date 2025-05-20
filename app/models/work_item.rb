# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: work_items
#
#  id              :integer          not null, primary key
#  closed          :boolean          default(FALSE), not null
#  description     :text
#  leaf            :boolean          default(TRUE), not null
#  name            :string           not null
#  path_ids        :integer          is an Array
#  path_names      :string(2047)
#  path_shortnames :string
#  shortname       :string(5)        not null
#  parent_id       :integer
#
# Indexes
#
#  index_work_items_on_parent_id  (parent_id)
#  index_work_items_on_path_ids   (path_ids)
#
# }}}

class WorkItem < ApplicationRecord
  include Evaluatable

  ### ASSOCIATIONS

  acts_as_tree order: 'shortname'

  has_one :client, dependent: :destroy, inverse_of: :work_item
  has_one :order, dependent: :destroy, inverse_of: :work_item
  has_one :accounting_post, dependent: :destroy, inverse_of: :work_item

  has_many :plannings,
           lambda { |work_item|
             joins(:work_item)
               .unscope(where: :work_item_id)
               .where('plannings.work_item_id = work_items.id AND ' \
                      '? = ANY (work_items.path_ids)', work_item.id)
           },
           dependent: :destroy

  has_many :worktimes,
           lambda { |work_item|
             joins(:work_item)
               .unscope(where: :work_item_id)
               .where('worktimes.work_item_id = work_items.id AND ' \
                      '? = ANY (work_items.path_ids)', work_item.id)
           }

  ### VALIDATIONS

  validates_by_schema except: :path_ids
  validates :name, :shortname,
            uniqueness: { scope: :parent_id, case_sensitive: false }

  ### CALLBACKS

  before_validation :upcase_shortname
  before_save :remember_name_changes
  after_create :generate_path_ids!
  after_create :reset_parent_leaf
  before_update :generate_path_ids
  after_destroy :reset_parent_leaf
  after_save :update_child_path_names, if: -> { @names_changed }

  ### SCOPES

  scope :list,         -> { order('path_shortnames') }
  scope :leaves,       -> { where(leaf: true) }
  scope :recordable,   -> { leaves.where(closed: false) }

  scope :with_worktimes_in_period, lambda { |order, from, to|
    where(id: order.worktimes.in_period(Period.new(from, to)).billable.select(:work_item_id))
  }

  ### INSTANCE METHODS

  def to_s
    name
  end

  def label_verbose
    "#{path_shortnames}: #{name}"
  end

  def tooltip
    description
  end

  def ancestor?(work_item_id)
    path_ids.include?(work_item_id)
  end

  def label_ancestry
    path_names
      .split("\n")[1..]
      .join(" #{Settings.work_items.path_separator} ")
  end

  def top_item
    self.class.find(path_ids[0])
  end

  def top?
    parent_id.nil?
  end

  def children?
    !leaf
  end

  def open?
    !closed
  end

  def with_ancestors(&)
    return enum_for(:with_ancestors) unless block_given?

    yield self
    parent.with_ancestors(&) if parent_id?
  end

  def self_and_descendants
    WorkItem.where('? = ANY (path_ids)', id)
  end

  # children that are not assigned to a special entity like client or order
  def categories
    children
      .joins('LEFT JOIN clients ON clients.work_item_id = work_items.id')
      .joins('LEFT JOIN orders ON orders.work_item_id = work_items.id')
      .joins('LEFT JOIN accounting_posts ON accounting_posts.work_item_id = work_items.id')
      .where(clients: { id: nil },
             orders: { id: nil },
             accounting_posts: { id: nil })
  end

  def employees
    Employee
      .where('id IN (?) OR id IN (?)',
             plannings.select(:employee_id),
             worktimes.select(:employee_id))
      .list
  end

  def move_times!(target)
    worktimes.update_all(work_item_id: target.is_a?(Integer) ? target : target.id)
  end

  def move_plannings!(target)
    plannings.update_all(work_item_id: target.is_a?(Integer) ? target : target.id)
  end

  def update_path_names!
    store_path_names
    save!
    update_child_path_names
  end

  def propagate_closed!(closed)
    self_and_descendants.update_all(closed:)
    self.closed = closed
    save!
  end

  private

  def remember_name_changes
    @names_changed = parent_id_changed? ||
                     name_changed? ||
                     shortname_changed?
    store_path_names if @names_changed
  end

  def generate_path_ids
    self.path_ids = parent ? parent.path_ids.clone.push(id) : [id]
  end

  def generate_path_ids!
    update_column(:path_ids, generate_path_ids)
  end

  def reset_parent_leaf
    return unless parent

    parent.update_column(:leaf, !parent.children.exists?)
  end

  def update_child_path_names
    children.each(&:update_path_names!)
    @names_changed = false
    true
  end

  def store_path_names
    self.path_shortnames = [parent.try(:path_shortnames), shortname].compact.join(Settings.work_items.path_separator)
    self.path_names = [parent.try(:path_names), name].compact.join("\n")
  end

  def upcase_shortname
    shortname&.upcase!
  end
end
