# app/controllers/concerns/search_pure.rb
module SearchPure
  extend ActiveSupport::Concern
  include Puree
  include Exceptions

  def get_uuids(limit=1,c_from=nil,c_to=nil,m_from=nil,m_to=nil)
    Puree.configure do |c|
      c.base_url = ENV['PURE_ENDPOINT']
      c.username = ENV['PURE_USERNAME']
      c.password = ENV['PURE_PASSWORD']
      c.basic_auth = true
    end
    c = Puree::Collection.new resource: :dataset

    puts c_from
    puts c_to
    puts m_from
    puts m_to
    metadata = c.find limit: limit,
                      offset: 0,
                      created_start:  c_from, # optional
                      created_end:    c_to, # optional
                      modified_start: m_from, # optional
                      modified_end:   m_to#,  # optional
    metadata
  rescue => e
    handle_exception(e, "Unable to connect to Pure. Please try again later.", "Probably Puree is unable to connect to Pure...", true) 
    # return an empty hash so that processing can continue
    {}
  end

  def get_uuids_created_from_tonow(from_no)
    d = DateTime.now
    from = d - Integer(from_no)
    c = get_uuids(nil,c_from=from.strftime("%Y-%m-%d"),c_to=d.tomorrow.strftime("%Y-%m-%d"))
    c

  end

  # TODO only update the ones that weren't in the created set
  def get_uuids_modified_from_tonow(from_no)
    d = DateTime.now
    from = d - Integer(from_no)
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
    d.metadata
  rescue => e
    handle_exception(e, "Unable to connect to Pure. Please try again later.", "Probably Puree is unable to connect to Pure...", true) 
    # return an empty hash so that processing can continue
    {}
  end

end
