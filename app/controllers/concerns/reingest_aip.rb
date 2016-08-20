# app/controllers/concerns/search_pure.rb
module ReingestAip
  extend ActiveSupport::Concern

  included do
    # ???
    attr_reader :aip
  end

  def reingest_aip(type,id)

    dataset = Dlibhydra::Dataset.find(id)
    aip = dataset.aips[0]
    dip = dataset.aips[0]
    dip.dip_status = 'APPROVE'
    dip.save

    unless aip.aip_uuid.nil?

      url = ENV['ARCHIVEMATICA_SS_URL']
      conn = Faraday.new(:url => url) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end

      path = '/api/v2/file/' + aip.aip_uuid + '/reingest/'

      body = '{"pipeline":"' + ENV['ARCHIVEMATICA_PIPELINE'] + '",
                "reingest_type":"' + type + '"}'

      params = {
          'username' => ENV['ARCHIVEMATICA_SS_USER'] ,
          'api_key' => ENV['ARCHIVEMATICA_SS_API_KEY']
      }

      response = conn.post do |req|
        req.url path
        req.headers['Content-Type'] = 'application/json'
        req.params = params
        req.body = body
      end

      # TODO some error handling!
      # TODO abstract faraday for re-use
      JSON.parse(response.body)

    end
  end

  def find_aip(id)
    Dlibhydra::Package.find(id)
  end

  def set_user_deposit(dataset,readme)
    self.set_aip_preflabel('AIP for ' + dataset.pure_uuid + " (deposited #{DateTime.now.strftime("%Y-%m-%d %R")}")
    self.set_readme(readme)
    self.set_aip_status('Not Yet Processed')
    self.set_aip_uuid('tbc') # temporary; need an aip_uid to be able to add to dataset.aips
    set_member_of(dataset)
    @aip.save
  end

  def set_member_of(dataset)
    dataset.aips << @aip
    dataset.save
  end

  def set_aip_uuid(uuid)
    @aip.aip_uuid = uuid
  end
  def set_current_path(location)
    @aip.aip_current_path = location
  end
  def set_aip_preflabel(title)
    @aip.preflabel = title
  end
  def set_readme(readme)
    @aip.readme = readme
  end
  def set_aip_status(status)
    # TODO check vocab?
    @aip.aip_status = status
  end

end