# frozen_string_literal: true

class Flatrate < ApplicationRecord
  belongs_to :accounting_post

  def label_verbose
    "#{name} (#{amount} #{Settings.defaults.currency}) - #{accounting_post}"
  end

  def periodicity
    super&.map(&:to_s) || []
  end

  def periodicity=(vals)
    cleaned = Array(vals).compact_blank
    super(cleaned.map(&:to_i))
  end
end
