# frozen_string_literal: true

json.array!(@categories) do |entry|
  json.extract! entry, :id, :name, :shortname
  json.label entry.name
end
