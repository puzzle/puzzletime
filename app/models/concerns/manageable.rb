# encoding: utf-8

# A Module to be mixed in by classes that may be managed by the ManageController.
#
# All methods are on the class side, so use 'extend Manageable' to use this Module.

# TODO remove
module Manageable

  # Lists all entries in the database of the corresponding class.
  def list(options = {})
    options[:order] ||= order_by
    where(options[:conditions]).
    includes(options[:include]).
    reorder(options[:order]).
    limit(options[:limit]).
    offset(options[:offset])
  end

  # Array with the German article, singular and plural name of the class.
  # Must overwrite in mixin class
  def labels
    ['Der', 'Eintrag', 'Einträge']
  end

  # Name of the class in German.
  def label
    labels[1]
  end

  # Plural name of the class in German.
  def label_plural
    labels[2]
  end

  # Article of the class in German
  def article
    labels[0]
  end

  # Data type of the field col of the class.
  def column_type(col)
    col = columns_hash[col.to_s]
    col.type if col   # col may not be in columns_hash (e.g. for associations). Return nil in this case
  end

  # Field sorting order for listing all entries.
  def order_by
    'name'
  end

  def puzzlebase_map
    nil
  end

  def local?
    puzzlebase_map.nil?
  end

end
