# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# A dummy model used for general testing.
class CrudTestModel < ApplicationRecord # :nodoc:
  belongs_to :companion, class_name: 'CrudTestModel'
  has_and_belongs_to_many :others, class_name: 'OtherCrudTestModel'
  has_many :mores, class_name: 'OtherCrudTestModel',
                   foreign_key: :more_id

  before_destroy :protect_if_companion

  validates :name, presence: true
  validates :rating, inclusion: { in: 1..10 }

  attr_protected nil if Rails.version < '4.0'

  def to_s
    name
  end

  def chatty
    remarks.size
  end

  private

  def protect_if_companion
    return if companion.blank?

    errors.add(:base, 'Cannot destroy model with companion')
    throw :abort
  end
end

# Second dummy model to test associations.
class OtherCrudTestModel < ApplicationRecord # :nodoc:
  has_and_belongs_to_many :others, class_name: 'CrudTestModel'
  belongs_to :more, class_name: 'CrudTestModel'

  scope :list, -> { order(:name) }

  def to_s
    name
  end
end
