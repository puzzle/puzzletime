# encoding: utf-8
# == Schema Information
#
# Table name: services
#
#  id     :integer          not null, primary key
#  name   :string           not null
#  active :boolean          default(TRUE), not null
#

class Service < ActiveRecord::Base

  has_many :accounting_posts

  scope :list, -> { order(:name) }

  protect_if :accounting_posts, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Budgetpositionen zugeordnet sind'

  validates_by_schema
  validates :name, uniqueness: true

  def to_s
    name
  end

end
