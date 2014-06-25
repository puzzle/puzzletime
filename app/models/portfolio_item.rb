# encoding: utf-8

# == Schema Information
#
# Table name: portfolio_items
#
#  id     :integer          not null, primary key
#  name   :string(255)      not null
#  active :boolean          default(TRUE), not null
#

class PortfolioItem < ActiveRecord::Base

  has_many :budget_items, class_name: 'Project'

  scope :list, -> { order(:name) }

  protect_if :budget_items, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Budgetpositionen zugeordnet sind'

  validates :name, uniqueness: true

  def to_s
    name
  end

end
