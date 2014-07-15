# == Schema Information
#
# Table name: employees
#
#  id                    :integer          not null, primary key
#  firstname             :string(255)      not null
#  lastname              :string(255)      not null
#  shortname             :string(3)        not null
#  passwd                :string(255)
#  email                 :string(255)      not null
#  management            :boolean          default(FALSE)
#  initial_vacation_days :float
#  ldapname              :string(255)
#  eval_periods          :string(3)        is an Array
#  department_id         :integer
#


Fabricator(:employee) do
  firstname { Faker::Name.first_name }
  lastname  { Faker::Name.last_name }
  shortname { ('A'..'Z').to_a.shuffle.take(3).join }
  email     { Faker::Internet.email }
end
