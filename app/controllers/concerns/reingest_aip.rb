# app/controllers/concerns/search_pure.rb
module ReingestAip
  extend ActiveSupport::Concern

  included do
    # ???
    attr_reader :aip
  end

  def reingest_aip(type,id)

    dataset = Dlibhydra::Dataset.find(id)
    aip = dataset.aip[0]
    dip = dataset.dip[0]
    dip.status = 'APPROVE'
    dip.save

    unless aip.aip_uuid.nil?

      url = ENV['ARCHIVEMATICA_SS_URL']
      conn = Faraday.new(:url => url) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end

      path = '/api/v2/file/' + aip.aip_uuid + '/reingest/'
      puts path
      params = '{"pipeline":"' + ENV['ARCHIVEMATICA_PIPELINE'] + '",
                "reingest_type":"' + type + '"}'
      puts params
      response = conn.post do |req|
        req.url path
        req.headers['Content-Type'] = 'application/json'
        req.body = params
      end

      JSON.parse(response.body)

    end
  end

  def find_aip(id)
    Dlibhydra::Aip.find(id)
  end

  def set_user_deposit(dataset,readme)
    self.set_aip_preflabel('AIP for ' + dataset.pure_uuid + " (deposited #{DateTime.now.strftime("%Y-%m-%d %R")}")
    self.set_readme(readme)
    self.set_data_status('Not Yet Processed')
    set_member_of(dataset)
    @aip.save
  end

  def set_member_of(dataset)
    dataset.aip << @aip
    dataset.save
  end

  def set_aip_uuid(uuid)
    @aip.aip_uuid = uuid
  end
  def set_current_path(location)
    @aip.current_path = location
  end
  def set_aip_preflabel(title)
    @aip.preflabel = title
  end
  def set_readme(readme)
    @aip.readme = readme
  end
  def set_data_status(status)
    # TODO check vocab?
    @aip.status = status
  end

end