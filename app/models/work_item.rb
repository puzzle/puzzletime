# == Schema Information
#
# Table name: work_items
#
#  id              :integer          not null, primary key
#  parent_id       :integer
#  name            :string(255)      not null
#  shortname       :string(5)        not null
#  description     :text
#  path_ids        :integer          is an Array
#  path_shortnames :string(255)
#  path_names      :string(2047)
#  leaf            :boolean          default(TRUE), not null
#  closed          :boolean          default(FALSE), not null
#

class WorkItem < ActiveRecord::Base
  include Evaluatable

  ### ASSOCIATIONS

  acts_as_tree order: 'shortname'

  has_one :client, dependent: :destroy, inverse_of: :work_item
  has_one :order, dependent: :destroy, inverse_of: :work_item
  has_one :accounting_post, dependent: :destroy, inverse_of: :work_item
  has_many :plannings, dependent: :destroy

  has_many :worktimes,
           ->(work_item) do
             joins(:work_item).
               unscope(where: :work_item_id).
               where('worktimes.work_item_id = work_items.id AND ' \
                   '? = ANY (work_items.path_ids)', work_item.id)
           end

  ### VALIDATIONS

  validates_by_schema except: :path_ids
  validates :name, :shortname,
            uniqueness: { scope: :parent_id, case_sensitive: false }

  ### CALLBACKS

  before_validation :upcase_shortname
  before_save :remember_name_changes
  # yep, this triggers before_update to generate path_ids after the work item got its id and saves it again
  after_create :save
  after_create :reset_parent_leaf
  after_destroy :reset_parent_leaf
  before_update :generate_path_ids
  after_save :update_child_path_names, if: -> { @names_changed }

  ### SCOPES

  scope :list,         -> { order('path_shortnames') }
  scope :leaves,       -> { where(leaf: true) }
  scope :recordable,   -> { leaves.where(closed: false) }

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
    path_names.split("\n")[1..-1].join(" #{Settings.work_items.path_separator} ")
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

  def with_ancestors(&block)
    return enum_for(:with_ancestors) unless block_given?
    yield self
    parent.with_ancestors(&block) if parent_id?
  end

  def self_and_descendants
    WorkItem.where('? = ANY (path_ids)', id)
  end

  # children that are not assigned to a special entity like client or order
  def categories
    children.joins('LEFT JOIN clients ON clients.work_item_id = work_items.id').
      joins('LEFT JOIN orders ON orders.work_item_id = work_items.id').
      joins('LEFT JOIN accounting_posts ON accounting_posts.work_item_id = work_items.id').
      where(clients: { id: nil },
            orders: { id: nil },
            accounting_posts: { id: nil })
  end

  def employees
    Employee.joins(worktimes: :work_item).
      where('? = ANY (work_items.path_ids)', id).
      list.
      uniq
  end

  def move_times!(target)
    worktimes.update_all(work_item_id: target)
  end

  def update_path_names!
    store_path_names
    save!
    update_child_path_names
  end

  def propagate_closed!(closed)
    self_and_descendants.leaves.update_all(closed: closed)
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

  def reset_parent_leaf
    if parent
      parent.update_column(:leaf, !parent.children.exists?)
    end
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
    shortname.upcase! if shortname
  end
end
