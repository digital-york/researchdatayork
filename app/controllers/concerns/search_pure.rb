# app/controllers/concerns/search_pure.rb
module SearchPure
  extend ActiveSupport::Concern
  include Puree

  included do
    #attr_reader :month, :contests
  end

  def get_uuids(limit=1,c_from=nil,c_to=nil,m_from=nil,m_to=nil)
    Puree::Configuration.configure do |c|
      c.endpoint = ENV['PURE_ENDPOINT']
      c.username = ENV['PURE_USERNAME']
      c.password = ENV['PURE_PASSWORD']
    end
    c = Puree::Collection.new(api: :dataset)
    c.find limit: limit,
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
    Puree::Configuration.configure do |c|
      c.endpoint = ENV['PURE_ENDPOINT']
      c.username = ENV['PURE_USERNAME']
      c.password = ENV['PURE_PASSWORD']
    end
    d = Puree::Dataset.new
    d.find uuid: uuid
    d
  end

end