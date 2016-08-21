json.array!(@response.files) do |file|
  json.id file.id
  json.text file.name
  json.parent @parent_folder == "root" ? "#" : @parent_folder 
  json.icon file.icon_link
  json.children file.mime_type === "application/vnd.google-apps.folder" ? true : false
end
