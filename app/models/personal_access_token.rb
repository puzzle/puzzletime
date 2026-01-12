# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class PersonalAccessToken < ApplicationRecord

  belongs_to :employee

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  attr_accessor :raw_token

  def self.search_token(token_string)
    return nil if token_string.blank?

    digest = OpenSSL::Digest::SHA256.hexdigest(token_string)
    find_by(token_digest: digest)
  end

  def self.create_for_employee(employee, token_name)
    raw = SecureRandom.hex(32)
    digest = OpenSSL::Digest::SHA256.hexdigest(raw)

    pat = create!(
      employee: employee,
      name: token_name,
      token_digest: digest
    )

    pat.raw_token = raw
    pat
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end
end
