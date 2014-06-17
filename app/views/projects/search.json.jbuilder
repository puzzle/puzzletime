json.array! @projects do |project|
  json.id project.id
  json.name project.name
  json.path_shortnames project.path_shortnames
  json.description project.inherited_description
end