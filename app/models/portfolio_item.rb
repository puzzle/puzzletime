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

  has_many :accounting_posts

  scope :list, -> { order(:name) }

  protect_if :accounting_posts, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Budgetpositionen zugeordnet sind'

  validates :name, uniqueness: true

  def to_s
    name
  end

end
