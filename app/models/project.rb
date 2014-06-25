# encoding: utf-8
# == Schema Information
#
# Table name: projects
#
#  id                    :integer          not null, primary key
#  client_id             :integer
#  name                  :string(255)      not null
#  description           :text
#  billable              :boolean          default(TRUE)
#  report_type           :string(255)      default("month")
#  description_required  :boolean          default(FALSE)
#  shortname             :string(3)        not null
#  offered_hours         :float
#  parent_id             :integer
#  department_id         :integer
#  path_ids              :integer          is an Array
#  freeze_until          :date
#  ticket_required       :boolean          default(FALSE)
#  path_shortnames       :string(255)
#  path_names            :string(2047)
#  leaf                  :boolean          default(TRUE), not null
#  inherited_description :text
#  closed                :boolean          default(FALSE), not null
#  offered_rate          :integer
#  portfolio_item_id     :integer
#  discount              :integer
#  reference             :string(255)
#

# (c) Puzzle itc, Berne:projects
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base

  PATH_SEPARATOR = '-'

  include Evaluatable
  include ReportType::Accessors

  acts_as_tree order: 'shortname'


  belongs_to :department
  belongs_to :client
  belongs_to :portfolio_item

  has_one :order

  has_many :worktimes,
           ->(project) do
             joins(:project).
             unscope(where: :project_id).
             where('worktimes.project_id = projects.id AND ' \
                   "#{project.id} = ANY (projects.path_ids)")
           end


  schema_validations except: :path_ids
  validates_presence_of :name, message: 'Ein Name muss angegeben werden'
  validates_uniqueness_of :name, scope: [:parent_id, :client_id], message: 'Dieser Name wird bereits verwendet'
  validates_presence_of :shortname, message: 'Ein Kürzel muss angegeben werden'
  validates_uniqueness_of :shortname, scope: [:parent_id, :client_id], message: 'Dieses Kürzel wird bereits verwendet'
  validates_presence_of :client_id, message: 'Das Projekt muss einem Kunden zugeordnet sein'
  validates :freeze_until, timeliness: { date: true, allow_blank: true }

  protect_if :worktimes, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Arbeitszeiten zugeordnet sind'

  before_save :remember_name_changes
  # yep, this triggers before_update to generate path_ids after the project got its id and saves it again
  after_create :save
  after_create :reset_parent_leaf
  after_destroy :reset_parent_leaf
  before_update :generate_path_ids
  after_save :update_child_path_names, if: -> { @names_changed }

  scope :list, -> { order('path_shortnames') }
  scope :leaves, -> { where(leaf: true) }
  scope :top, -> { where(parent_id: nil) }

  def to_s
    name
  end

  def client_name
    client.name if client
  end

  def department_name
    department.name if department
  end

  def self.top_projects
    top.list
  end

  def label_verbose
    "#{path_shortnames}: #{name}"
  end

  def tooltip
    inherited_description
  end

  def ancestor?(project_id)
    path_ids.include?(project_id)
  end

  def label_ancestry
    path_names.split("\n")[1..-1].join(" #{PATH_SEPARATOR} ")
  end

  def top_project
    self.class.find(path_ids[0])
  end

  def top?
    parent_id.nil?
  end

  def sub_projects?
    !leaf
  end

  def leaves
    leaf? ? [self] : self_and_descendants.list.leaves
  end

  def self_and_descendants
    parent_id_condition = path_ids.each_with_index.collect {|id, i| "path_ids[#{i+1}] = #{id}" }.join(' AND ')
    Project.where(parent_id_condition)
  end

  def employees
    Employee.joins(worktimes: :project).
             where('? = ANY (projects.path_ids)', id).
             list.
             uniq
  end

  def move_times_to(other)
    Projecttime.update_all ['project_id = ?', other.id], ['project_id = ?', id]
  end

  def <=>(other)
    return super(other) unless other.is_a?(Project)
    return 0 if id && id == other.id

    path_shortnames <=> other.path_shortnames
  end

  def update_path_names!
    store_path_names
    save!
    update_child_path_names
  end

  protected

  def validate_worktime(worktime)
    if worktime.report_type < report_type
      worktime.errors.add(:report_type,
                          "Der Reporttyp muss eine Genauigkeit von mindestens #{report_type.name} haben")
    end

    if worktime.report_type != AutoStartType::INSTANCE && description_required? && worktime.description.blank?
      worktime.errors.add(:description, 'Es muss eine Bemerkung angegeben werden')
    end

    if worktime.report_type != AutoStartType::INSTANCE && ticket_required? && worktime.ticket.blank?
      worktime.errors.add(:ticket, 'Es muss ein Ticket angegeben werden')
    end

    validate_worktime_frozen(worktime)
  end

  def validate_worktime_frozen(worktime)
    freeze = latest_freeze_until
    if freeze &&
       worktime.work_date &&
       (worktime.work_date <= freeze ||
        (!worktime.new_record? && Worktime.find(worktime.id).work_date <= freeze))
        worktime.errors.add(:work_date, "Die Zeiten vor dem #{I18n.l(freeze)} wurden für dieses Projekt eingefroren und können nicht mehr geändert werden. Um diese Arbeitszeit trotzdem zu bearbeiten, wende dich bitte an den entsprechenden Projektleiter.")
        false
    end
  end

  def latest_freeze_until
    if parent.nil?
      freeze_until
    else
      parent_freeze_until = parent.latest_freeze_until
      if freeze_until.nil?
        parent_freeze_until
      elsif parent_freeze_until.nil?
        freeze_until
      else
        [freeze_until, parent_freeze_until].max
      end
    end
  end

  def remember_name_changes
    @names_changed = parent_id_changed? || client_id_changed? ||
                     name_changed? || shortname_changed? || description_changed?
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
  end

  def store_path_names
    if parent
      self.path_shortnames = parent.path_shortnames + PATH_SEPARATOR + shortname
      self.path_names = parent.path_names + "\n" + name
      self.inherited_description = description.presence || parent.inherited_description
    else
      self.path_shortnames = client.shortname + PATH_SEPARATOR + shortname
      self.path_names = client.name + "\n" + name
      self.inherited_description = description
    end
  end

end
