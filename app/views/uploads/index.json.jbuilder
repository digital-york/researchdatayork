json.array!(@uploads) do |upload|
  json.extract! upload, :id, :uuid
  json.url upload_url(upload, format: :json)
end
