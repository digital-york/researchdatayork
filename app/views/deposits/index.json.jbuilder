json.array!(@deposits) do |deposit|
  json.extract! deposit, :numFound 
  json.url deposit_url(deposit, format: :json)
end
