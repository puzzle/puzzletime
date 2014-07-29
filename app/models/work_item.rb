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

  ### ASSOCIATIONS

  acts_as_tree order: 'shortname'

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

  ### VALIDATIONS

  schema_validations except: :path_ids
  validates :name, :shortname,
            presence: true,
            uniqueness: { scope: :parent_id, case_sensitive: false }

  ### CALLBACKS

  before_validation :upcase_shortname
  before_save :remember_name_changes
  # yep, this triggers before_update to generate path_ids after the project got its id and saves it again
  after_create :save
  after_create :reset_parent_leaf
  after_destroy :reset_parent_leaf
  before_update :generate_path_ids
  after_save :update_child_path_names, if: -> { @names_changed }

  ### SCOPES

  scope :list, -> { order('path_shortnames') }
  scope :recordable, -> { where(leaf: true, closed: false) }

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

  def sub_projects?
    !leaf
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

  def update_path_names!
    store_path_names
    save!
    update_child_path_names
  end

  private

  def remember_name_changes
    @names_changed = parent_id_changed? ||
                     name_changed? ||
                     shortname_changed?
    store_path_names if @names_changed
  end

  def generate_path_ids
    self.path_ids = top? ? [id] : parent.path_ids.clone.push(id)
  end

  def reset_parent_leaf
    if parent
      parent.update_column(:leaf, !parent.children.exists?)
    end
  end

  def update_child_path_names
    children.each do |c|
      c.update_path_names!
    end
    @names_changed = false
    true
  end

  def store_path_names
    if parent
      self.path_shortnames = parent.path_shortnames + Settings.work_items.path_separator + shortname
      self.path_names = parent.path_names + "\n" + name
    else
      self.path_shortnames = shortname
      self.path_names = name
    end
  end

  def upcase_shortname
    shortname.upcase! if shortname
  end

end
