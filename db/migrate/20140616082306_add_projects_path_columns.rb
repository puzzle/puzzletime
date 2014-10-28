# define deleted models that are used in the migration
class Project < ActiveRecord::Base
  belongs_to :parent, class_name: 'Project'

  def update_path_names!
  end

  def reset_parent_leaf
    if parent
      parent.update_column(:leaf, false)
      parent.reset_parent_leaf
    end
  end
end

class AddProjectsPathColumns < ActiveRecord::Migration
  def up
    add_column :projects, :path_shortnames, :string
    add_column :projects, :path_names, :string, limit: 2047
    add_column :projects, :leaf, :boolean, null: false, default: true
    add_column :projects, :inherited_description, :text

    Project.where(parent_id: nil).find_each do |p|
      p.update_path_names!
    end

    Project.find_each do |p|
      p.reset_parent_leaf
      p.update_column(:inherited_description, inherited_description(p))
    end
  end

  def down
    remove_column :projects, :inherited_description
    remove_column :projects, :path_shortnames
    remove_column :projects, :path_names
    remove_column :projects, :leaf
  end

  private

  def inherited_description(p)
    if !p.description? && p.parent
      inherited_description(p.parent)
    else
      p.description
    end
  end
end
