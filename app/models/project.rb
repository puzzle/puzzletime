# encoding: utf-8
# == Schema Information
#
# Table name: projects
#
#  id                   :integer          not null, primary key
#  client_id            :integer
#  name                 :string(255)      not null
#  description          :text
#  billable             :boolean          default(TRUE)
#  report_type          :string(255)      default("month")
#  description_required :boolean          default(FALSE)
#  shortname            :string(3)        not null
#  offered_hours        :float
#  parent_id            :integer
#  department_id        :integer
#  path_ids             :integer          is an Array
#  freeze_until         :date
#  ticket_required      :boolean          default(FALSE)
#


# (c) Puzzle itc, Berne:projects
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base

  include Evaluatable
  extend Manageable
  include ReportType::Accessors

  acts_as_tree order: 'name'

  # All dependencies between the models are listed below.
  has_many :projectmemberships,
           dependent: :destroy

  belongs_to :department
  belongs_to :client

  has_many :worktimes,
           ->(project) do
             joins(:project).
             unscope(where: :project_id).
             where("worktimes.project_id = projects.id AND " \
                   "#{project.id} = ANY (projects.path_ids)")
           end

  before_validation DateFormatter.new('freeze_until')

  validates_presence_of :name, message: 'Ein Name muss angegeben werden'
  validates_uniqueness_of :name, scope: [:parent_id, :client_id], message: 'Dieser Name wird bereits verwendet'
  validates_presence_of :shortname, message: 'Ein Kürzel muss angegeben werden'
  validates_uniqueness_of :shortname, scope: [:parent_id, :client_id], message: 'Dieses Kürzel wird bereits verwendet'
  validates_presence_of :client_id, message: 'Das Projekt muss einem Kunden zugeordnet sein'
  validates_presence_of :department_id, message: 'Das Projekt muss einem Gesch&auml;ftsbereich zugeordnet sein'

  before_destroy :protect_worktimes

  # yep, this triggers before_update to generate path_ids after the project got its id and saves it again
  after_create :save
  before_update :generate_path_ids

  scope :list, -> do
    includes(:client).
    references(:client).
    order('clients.shortname, projects.name')
  end

  ##### interface methods for Manageable #####

  def self.labels
    %w(Das Projekt Projekte)
  end

  def self.list(options = {})
    options[:include] ||= :client
    options[:order] ||= 'clients.shortname, projects.name'
    super(options)
  end

  def self.puzzlebaseMap
    Puzzlebase::CustomerProject
  end

  def self.columnType(col)
    case col
      when :report_type then :report_type
      else super col
      end
  end

  def self.leaves
    list.select { |project| project.leaf? }
  end

  def self.top_projects
    list.select { |c| c.top? }
  end

  def label_verbose
  	 path_labels = (ancestor_projects + [self]).collect(&:shortname)
    "#{client.shortname}-#{path_labels.join('-')}: #{name}"
  end

  def tooltip
    ([self] + ancestor_projects.reverse).each do |p|
      return p.description if p.description.present?
    end
    nil
  end

  def ancestor_projects
    @ancestor_projects ||= begin
      ids = Array(path_ids)[0..-2]
      hash = {}
      self.class.find(ids).each { |p| hash[p.id] = p }
      ids.collect { |id| hash[id.to_i] }
    end
  end

  def label_ancestry
  	 (ancestor_projects + [self]).collect(&:name).join(' - ')
  end

  def top_project
    self.class.find(path_ids[0])
  end

  def top?
    parent_id.nil?
  end

  def children?
    !children.empty?
  end

  def leaf?
    children.empty?
  end

  def leaves
    return [self] if leaf?
    children.collect { |p| p.leaves }.flatten
  end

  def managed_employees
    Employee.joins(projectmemberships: :project).
             where('projectmemberships.project_id IN (?) AND projectmemberships.active', path_ids).
             order('lastname, firstname').
             uniq
  end

  def employees
    Employee.joins(worktimes: :project).
             where('? = ANY (projects.path_ids)', id).
             order('lastname, firstname').
             uniq
  end

  def freeze_until
    # cache date to prevent endless string_to_date conversion
    @freeze_until ||= read_attribute(:freeze_until)
  end

  def freeze_until=(value)
    write_attribute(:freeze_until, value)
    @freeze_until = nil
  end

  def move_times_to(other)
    Projecttime.update_all ['project_id = ?', other.id], ['project_id = ?', id]
  end

  def generate_path_ids
    self.path_ids = top? ? [id] : parent.path_ids.clone.push(id)
  end

  def <=>(other)
    return super(other) unless other.is_a?(Project)
    return 0 if id == other.id? && id

    "#{client.shortname}: #{label_ancestry}" <=> "#{other.client.shortname}: #{other.label_ancestry}"
  end

  def validate_worktime(worktime)
    if worktime.report_type < report_type
      worktime.errors.add(:report_type,
                          "Der Reporttyp muss eine Genauigkeit von mindestens #{report_type.name} haben")
    end

    if worktime.report_type != AutoStartType::INSTANCE && description_required? && worktime.description.blank?
      worktime.errors.add(:description, 'Es muss eine Beschreibung angegeben werden')
    end

    if worktime.report_type != AutoStartType::INSTANCE && ticket_required? && worktime.ticket.blank?
      worktime.errors.add(:ticket, 'Es muss ein Ticket/Task angegeben werden')
    end

    validate_worktime_frozen(worktime)
  end

  def validate_worktime_frozen(worktime)
    if freeze = latest_freeze_until
      if worktime.work_date <= freeze || (!worktime.new_record? && Worktime.find(worktime.id).work_date <= freeze)
        worktime.errors.add(:work_date, "Die Zeiten vor dem #{freeze.strftime(DATE_FORMAT)} wurden für dieses Projekt eingefroren und können nicht mehr geändert werden. Um diese Arbeitszeit trotzdem zu bearbeiten, wende dich bitte an den entsprechenden Projektleiter.")
        false
      end
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

end
