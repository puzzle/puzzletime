# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# run with
# rails runner bin/import_master_data.rb file.csv

def get(hash, option_keys)
  option_keys.each_with_object({}) { |v, h| h[v] = hash[v] }
end

filename = ARGV.first

header_map = {
  'Kürzel' => :shortname,
  'Vorname' => :firstname,
  'Name' => :lastname,
  'Adresse' => :street,
  'PLZ' => :postal_code,
  'Ort' => :city,
  'AHV-Nummer' => :social_insurance,
  'Geburtstag' => :birthday,
  'Zivilstand' => :marital_status,
  'Telefon Büro' => :phone_office,
  'Telefon Privat' => :phone_private,
  'Notfallperson' => :emergency_contact_name,
  'Notfallnummer' => :emergency_contact_phone
}

marital_status_map = {
  'ledig' => :single,
  'verheiratet' => :married,
  'verwittwet' => :widowed,
  'eingetragene partnerschaft' => :civil_partnership,
  'geschieden' => :divorced
}

phone_converter = ->(v) { v.tr('-', ' ') }

converters = {
  shortname: ->(v) { v ? v.strip.upcase : nil },
  birthday: ->(v) { Date.parse(v) },
  marital_status: ->(v) { v ? marital_status_map[v.downcase] : nil },
  phone_office: phone_converter,
  phone_private: phone_converter
}
converters.default = ->(v) { v.is_a?(String) ? v.strip : v }

csv_text = File.read(filename)
csv = CSV.parse(csv_text,
                converters: ->(v, k) { converters[k.header].call(v) },
                headers: true,
                header_converters: ->(h) { header_map[h] })
csv.map(&:to_hash).each do |row|
  e = Employee.find_by(get(row, [:shortname, :firstname, :lastname])) ||
      Employee.find_by(get(row, [:firstname, :lastname])) ||
      Employee.find_by(get(row, [:shortname])) ||

  unless e
    puts "#{row[:lastname]} #{row[:firstname]} wurde nicht im PuzzleTime gefunden."
    next
  end

  e.attributes = get(row, [:street,
                           :postal_code,
                           :city,
                           :social_insurance,
                           :birthday,
                           :marital_status,
                           :phone_office,
                           :phone_private,
                           :emergency_contact_name,
                           :emergency_contact_phone])

  e.save!
end
