namespace :pure do
  desc "TODO"

  task generate_json: :environment do
    require 'puree'
    # https://pure.york.ac.uk/ws/rest
    c = Puree::Collection.new(resource_type: :dataset)

  # Get three minimal datasets, starting at record ten, created and modified in January 2016.
    c.get endpoint:       'https://pure.york.ac.uk/ws/rest',
          username:       'wsadmin',
          password:       '5z7wGDM8',
          limit:          1  # optional, default 20

    c.uuid.each do |uu|
      d = Puree::Dataset.new
      d.get endpoint:       'https://pure.york.ac.uk/ws/rest',
            username:       'wsadmin',
            password:       '5z7wGDM8',
            uuid:     uu
      require 'json'
      File.write('metadata.json', d.metadata.to_json)
    end


  end
end
