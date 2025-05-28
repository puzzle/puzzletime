# frozen_string_literal: true

class Flatrate < ApplicationRecord
  belongs_to :accounting_post

  def label_verbose
    "#{name} (#{accounting_post.name})"
  end

  (0..11).each do |i|
    define_method(:"periodicity_#{i}") do
      periodicity[i].to_i
    rescue StandardError
      0
    end

    define_method(:"periodicity_#{i}=") do |val|
      current = periodicity.dup
      current[i] = val.to_i
      self.periodicity = current # triggers ActiveRecord change tracking
    end
  end

  # Ensure periodicity is always an array of 12 integers
  def periodicity
    super&.map(&:to_i)&.fill(0, super.size...12) || Array.new(12, 0)
  end

  def periodicity=(vals)
    super(Array(vals).map(&:to_i).fill(0, vals.size...12))
  end
end
