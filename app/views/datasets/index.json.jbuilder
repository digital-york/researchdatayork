json.array!(@datasets) do |dataset|
  json.extract! dataset, :id
  json.url dataset_url(dataset, format: :json)
end
