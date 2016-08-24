# app/controllers/concerns/search_pure.rb
module SearchPure
  extend ActiveSupport::Concern
  include Puree

  def get_uuids(limit=1,c_from=nil,c_to=nil,m_from=nil,m_to=nil)
    Puree.configure do |c|
      c.base_url = ENV['PURE_ENDPOINT']
      c.username = ENV['PURE_USERNAME']
      c.password = ENV['PURE_PASSWORD']
      c.basic_auth = true
    end
    c = Puree::Collection.new resource: :dataset
    metadata = c.find limit: limit,
          offset: nil,
          created_start:  c_from, # optional
          created_end:    c_to, # optional
          modified_start: m_from, # optional
          modified_end:   m_to,  # optional
          instance: true
    metadata
  end

  def get_uuids_created_from_tonow(from_no)
    d = DateTime.now
    from = d - Integer(from_no)
    puts d
    puts from
    c = get_uuids(nil,c_from=from.strftime("%Y-%m-%d"),c_to=d.tomorrow.strftime("%Y-%m-%d"))
    c

  end

  def get_uuids_modified_from_tonow(from_no)
    d = DateTime.now
    from = d - Integer(from_no)
    puts d
    puts from
    c = get_uuids(nil,nil,nil,m_from=from.strftime("%Y-%m-%d"),m_to=d.tomorrow.strftime("%Y-%m-%d"))
    c
  end

  def get_pure_dataset(uuid)

    Puree.configure do |c|
      c.base_url = ENV['PURE_ENDPOINT']
      c.username = ENV['PURE_USERNAME']
      c.password = ENV['PURE_PASSWORD']
      c.basic_auth = true
    end
    d = Puree::Dataset.new
    if uuid.include? '-'
      d.find uuid: uuid
    else
      d.find id: uuid
    end
    d
  end

end