# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: contacts
#
#  id            :integer          not null, primary key
#  crm_key       :string
#  email         :string
#  firstname     :string
#  function      :string
#  invoicing_key :string
#  lastname      :string
#  mobile        :string
#  phone         :string
#  created_at    :datetime
#  updated_at    :datetime
#  client_id     :integer          not null
#
# Indexes
#
#  index_contacts_on_client_id  (client_id)
#
# }}}

class Contact < ApplicationRecord
  CRM_ID_PREFIX = 'crm_'

  belongs_to :client

  has_many :order_contacts, dependent: :destroy
  has_many :orders, through: :order_contacts
  has_many :billing_addresses, dependent: :nullify

  validates_by_schema
  validates :firstname, :lastname, presence: true
  validates :email, email: true, allow_blank: true
  validates :invoicing_key, uniqueness: true, allow_blank: true

  scope :list, -> { order(:lastname, :firstname) }

  def to_s
    "#{lastname} #{firstname}"
  end

  def id_or_crm
    id || "#{CRM_ID_PREFIX}#{crm_key}"
  end
end
