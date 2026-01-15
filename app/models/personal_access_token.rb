# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class PersonalAccessToken < ApplicationRecord
  ALLOWED_SCOPES = %w[read:all write:all].freeze

  serialize :scopes, type: Array, coder: JSON

  belongs_to :employee

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validate :scopes_must_be_allowed

  attr_accessor :raw_token

  def self.search_token(token_string)
    return nil if token_string.blank?

    digest = OpenSSL::Digest::SHA256.hexdigest(token_string)
    find_by(token_digest: digest)
  end

  def self.create_for_employee(employee, token_name, scopes: ['read:all'])
    valid_scopes = Array(scopes) & ALLOWED_SCOPES
    raw = SecureRandom.hex(32)
    digest = OpenSSL::Digest::SHA256.hexdigest(raw)

    pat = create!(
      employee: employee,
      name: token_name,
      token_digest: digest,
      scopes: valid_scopes
    )

    pat.raw_token = raw
    pat
  end

  def can?(action, resource = :all)
    action = action.to_s
    resource = resource.to_s
    current_scopes = scopes || []

    return true if current_scopes.include?('write:all')
    return true if action == 'read' && current_scopes.include?('read:all')

    # Future-proof: always returns false but ALLOWED_SCOPES could be expanded with more granular scopes
    current_scopes.include?("#{action}:#{resource}")
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  private

  def scopes_must_be_allowed
    return if scopes.is_a?(Array) && (scopes - ALLOWED_SCOPES).empty?

    errors.add(:scopes, 'enthalten ungültige Werte')
  end
end
