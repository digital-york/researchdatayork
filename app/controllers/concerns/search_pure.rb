# app/controllers/concerns/search_pure.rb
module SearchPure
  extend ActiveSupport::Concern
  include Puree

  included do
    #attr_reader :month, :contests
  end

  def get_uuids(limit=1,c_from=nil,c_to=nil,m_from=nil,m_to=nil)
    c = Puree::Collection.new(resource_type: :dataset)
    c.get endpoint: ENV['PURE_ENDPOINT'],
          username: ENV['PURE_USERNAME'],
          password: ENV['PURE_PASSWORD'],
          limit: limit,
          offset: nil,
          created_start:  c_from, # optional
          created_end:    c_to, # optional
          modified_start: m_from, # optional
          modified_end:   m_to  # optional
    c
  end

  def get_uuids_created_from_tonow(from)
    d = DateTime.now
    if from == "24"
      from = DateTime.now.yesterday.strftime("%Y-%m-%d")
    end
    c = get_uuids(nil,c_from=from,c_to=d.tomorrow.strftime("%Y-%m-%d"))
    c

  end

  def get_uuids_modified_from_tonow(from)
    d = DateTime.now
    if from == "24"
      from = DateTime.now.yesterday.strftime("%Y-%m-%d")
    end
    c = get_uuids(nil,nil,nil,m_from=from,m_to=d.tomorrow.strftime("%Y-%m-%d"))
    c
  end

  def get_pure_dataset(uuid)
    d = Puree::Dataset.new
    d.get endpoint: ENV['PURE_ENDPOINT'],
          username: ENV['PURE_USERNAME'],
          password: ENV['PURE_PASSWORD'],
          uuid: uuid
    d
  end

end