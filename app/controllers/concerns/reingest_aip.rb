# app/controllers/concerns/search_pure.rb
module ReingestAip
  extend ActiveSupport::Concern
  include Exceptions

  included do
    # ???
    attr_reader :aip
  end

  def reingest_aip(type, id)
    dataset = Dlibhydra::Dataset.find(id)
    aip = dataset.aips[0]
    dip = dataset.aips[0]

    unless aip.aip_uuid.nil?

      url = ENV['ARCHIVEMATICA_SS_URL']
      conn = Faraday.new(url: url) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end

      path = '/api/v2/file/' + aip.aip_uuid + '/reingest/'

      body = '{"pipeline":"' + ENV['ARCHIVEMATICA_PIPELINE'] + '",
                "reingest_type":"' + type + '"}'

      params = {
        'username' => ENV['ARCHIVEMATICA_SS_USER'],
        'api_key' => ENV['ARCHIVEMATICA_SS_API_KEY']
      }

      begin
        response = conn.post do |req|
          req.url path
          req.headers['Content-Type'] = 'application/json'
          req.params = params
          req.body = body
        end
      rescue => e
        handle_exception(e, "Unable to connect to Archivematica. Please try again later.", "Dataset id: " + id, true)
        return ""
      end 

      # make sure that the response was 200 series
      # In the past, I have also ignored this 500 error (uncomment 'or' clause if necessary):
      # Error in approve reingest API. Pipeline Archivematica on am-local (1937aad1-c5fe-4bb9-9d8a-0bd3488204c5) returned an unexpected status code: 500 (Permission denied)
      if response.status and (response.status.to_s.match(/^2\d\d$/)
          # or (response.status.to_s.match(/^5\d\d$/) and response.body.include? 'Permission denied')
          )
        dip.dip_status =  approve_reingest(aip.id, aip.aip_uuid, id)
        dip.save
      else
        begin
          raise
        rescue => e
          begin
            json_response = JSON.parse(response.body)
            if json_response.has_key?("message")
              handle_exception(e, "Unable to reingest AIP: " + json_response['message'], "Response from Archivematica: " + json_response['message'])
            elsif json_response.has_key?("error_message")
              handle_exception(e, "Unable to reingest AIP - error from Archivematica: " + json_response['error_message'], "Error response from Archivematica: " + json_response['error_message'])
            end
          rescue => e2
            if response.body and !response.body.empty?
              handle_exception(e2, "Unable to reingest AIP: " + response.body, "Dataset id: " + id + "\nError from Archivematica: " + response.body, true)
            else 
              handle_exception(e2, "Unexpected response from Archivematica. Make sure the Archivematica credentials are valid and that the dataset exists in Archivematica", "Dataset id: " + id, true)
            end
          end
          return ""
        end
      end
      # TODO abstract faraday for re-use
      JSON.parse(response.body)
    end
  rescue => e
    handle_exception(e, "Unable to connect to Archivematica. Please try again later.", "Dataset id: " + id, true)
    return ""
  end

  def approve_reingest(aip_id, aip_uuid, dataset_id)

    # let's make sure the ingest request is done
    sleep(5)

    url = ENV['ARCHIVEMATICA_URL']
    conn = Faraday.new(url: url) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP

    end
    path = '/api/ingest/reingest/approve'

    begin
      response = conn.post path, {
          :name => aip_id,
          :uuid => aip_uuid,
          :api_key => ENV['ARCHIVEMATICA_API_KEY'],
          :username => ENV['ARCHIVEMATICA_USER']
      }

    rescue => e
      handle_exception(e, "Unable to connect to Archivematica. Please try again later.", "Dataset id: " + dataset_id, true)
      return nil
    end
    if response.status and response.status.to_s.match(/^2\d\d$/)
      # now that reingest request has been made successfully, set dip status to approved
      return 'APPROVED'
    else
      begin
        raise
      rescue => e
        begin
          json_response = JSON.parse(response.body)
          handle_exception(e, "Unable to approve reingest for AIP: " + json_response['message'], "Response from Archivematica: " + json_response['message'])
        rescue => e2
          if response.body and !response.body.empty?
            handle_exception(e2, "Unable to approve reingest for AIP: " + response.body, "Dataset id: " + dataset_id + "\nError from Archivematica: " + response.body, true)
          else
            handle_exception(e2, "Unexpected response from Archivematica. Make sure the Archivematica credentials are valid and that the dataset exists in Archivematica", "Dataset id: " + id, true)
          end
        end
        return nil
      end
    end
  end



  def find_aip(id)
    Dlibhydra::Package.find(id)
  end

  def set_user_deposit(dataset, readme)
    set_aip_title('AIP for ' + dataset.pure_uuid + " (deposited #{DateTime.now.strftime('%Y-%m-%d %R')}")
    dataset.readme = readme
    set_aip_status('Not Yet Processed')
    set_aip_uuid('tbc') # temporary; need an aip_uid to be able to add to dataset.aips
    add_aip_permissions
    set_member_of(dataset)
    @aip.save
  end

  def set_member_of(dataset)
    dataset.packaged_by << @aip
    dataset.save
  end

  def set_aip_uuid(uuid)
    @aip.aip_uuid = uuid
  end

  def set_current_path(location)
    @aip.aip_current_path = location
  end

  def set_aip_title(title)
    @aip.title = [title]
  end

  def set_aip_status(status)
    # TODO: check vocab?
    @aip.aip_status = status
  end

  def add_aip_permissions
    # generate permissions for a new object
    if @aip.access_control.nil?
      @aip.permissions # generate permissions
      write_aip_permissions # add write permissions
    end
  end

  # Add the default depositor
  # This required the dlibhydra depositor generator to have been run
  def write_aip_permissions
    @aip.apply_depositor
  end
end
