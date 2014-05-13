# encoding: utf-8

class Puzzlebase::Base < ActiveRecord::Base

  # Set up database connection to puzzlebase for all subclasses of Base
  establish_connection :puzzlebase

  # The model class the Puzzlebase model maps to.
  MAPS_TO = nil
  # The attributes of the model class that map to the puzzlebase attributes.
  MAPPINGS = {}
  # Find the puzzlebase records to import according to these options
  FIND_OPTIONS = {}

  # Set database properties
  def self.table_name
    "TBL_#{reset_table_name}"
  end

  def self.primary_key
    "PK_#{reset_table_name}"
  end

  # Synchronizes Clients, Projects, Employees and Employments from puzzlebase
  def self.synchronizeAll
    resetErrors
    # synchronizes clients and projects
    Puzzlebase::CustomerProject.updateAll
    # synchronizes employees and employments
    Puzzlebase::Employee.updateAll
    errors
  end

  # Synchronizes the entries for this puzzlebase table.
  def self.synchronize
    resetErrors
    updateAll
    errors
  end

  def self.removeUnused
    removeUnusedExcept findAll
  end

  protected

  # Updates all entries of the receiver from puzzlebase
  def self.updateAll
    findAll.each { |original| updateLocal original }
  end

  # Updates or creates a corresponding local entry from an original entry
  # in puzzlebase and saves it.
  def self.updateLocal(original)
    local = findLocal(original)
    local ||= self::MAPS_TO.new
    updateAttributes local, original
    setReference local, original
    saveUpdated local
  end

  # Updates all attributes of the local entry from the original entry in puzzlebase.
  # based on the MAPPINGS defined.
  def self.updateAttributes(local, original)
    self::MAPPINGS.each_pair do |localAttr, originalAttr|
      local.send(:"#{localAttr}=", original.send(originalAttr))
    end
  end

  # Saves an update local entry and logs potential error messages.
  def self.saveUpdated(local)
    success = local.save
    errors.push local unless success
    success
  end

  def self.findLocal(original)
    o = localFindOptions(original)
    self::MAPS_TO.where(o[:conditions]).
                  joins(o[:joins]).
                  includes(o[:include]).
                  first
  end

  def self.findAll
    o = self::FIND_OPTIONS
    where(o[:conditions]).
    includes(o[:include]).
    order(o[:order]).
    joins(o[:joins]).
    select(o[:select])
  end

  # SQL select conditions for entries with references to other tables
  def self.localFindOptions(original)
    { conditions: ['shortname = ?', original.send(self::MAPPINGS[:shortname])] }
  end


  def self.removeUnusedExcept(originals, condition = nil)
    base_shortnames = originals.collect { |original| "'#{original.send(self::MAPPINGS[:shortname])}'" }
    conditions = ''
    conditions = "shortname NOT IN (#{base_shortnames.join(', ')})" unless base_shortnames.empty?
    conditions += ' AND ' if conditions.size > 0 && condition
    conditions += condition if condition
    only_local = self::MAPS_TO.where(conditions)
    only_local.each do |local|
      local.destroy if local.worktimes(true).empty?
    end
  end

  # Sets the local reference based on the original entry from puzzlebase
  def self.setReference(local, original)
  end

  # Helper method to compute the table name in puzzlebase
  def self.table_id
    name.demodulize.upcase
  end

  # Returns an Array of errorenous entries resulting from a synchronization process.
  def self.errors
    @@errors
  end

  # Resets all errorenous entries.
  def self.resetErrors
    @@errors = []
  end

end
