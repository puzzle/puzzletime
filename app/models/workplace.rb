# frozen_string_literal: true

# {{{
# == Schema Information
#
# Table name: workplaces
#
#  id   :bigint           not null, primary key
#  name :string
#
# }}}

class Workplace < ApplicationRecord
  validates_by_schema
  validates :name, uniqueness: { case_sensitive: false }

  scope :list, -> { order(:name) }

  def to_s
    name
  end
end
