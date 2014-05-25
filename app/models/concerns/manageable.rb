# encoding: utf-8

# A Module to be mixed in by classes that may be managed by the ManageController.
#
# All methods are on the class side, so use 'extend Manageable' to use this Module.
module Manageable

  def label
    model_name.human
  end

  def puzzlebase_map
    nil
  end

  def local?
    puzzlebase_map.nil?
  end

end
