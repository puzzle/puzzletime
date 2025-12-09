# frozen_string_literal: true

# {{{
# == Schema Information
#
# Table name: authentications
#
#  id           :bigint           not null, primary key
#  provider     :string
#  token        :string
#  token_secret :string
#  uid          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  employee_id  :bigint
#
# Indexes
#
#  index_authentications_on_employee_id  (employee_id)
#
# }}}
class Authentication < ApplicationRecord
  belongs_to :employee
end
