# app/controllers/concerns/search_pure.rb
module CreateDip
  extend ActiveSupport::Concern

  included do
    # ???
    attr_reader :dip
  end

  def create_dip
    @dip = Dlibhydra::Dip.new
  end

  def save_dip
    @dip.save
  end

  def update_dip(id, uuid)
    dataset = Dlibhydra::Dataset.find(id)
    @dip = dataset.dip[0]
    dip_info = get_dip_details(uuid)
    ingest_dip(dip_info['current_path'])
    set_dip_current_path(dip_info['current_path'])
    set_dip_uuid(dip_info['uuid'])
    set_dip_status(dip_info['status'])
    set_dip_current_full_path(dip_info['current_path'])
    set_dip_current_location(dip_info['current_location'])
    set_dip_resource_uri(dip_info['resource_uri'])
    set_dip_package_size(dip_info['size'])
    set_dip_origin_pipeline(dip_info['origin_pipeline'])
    save_dip

    'DIP updated with objects'
  end

  def set_dip_member_of(dataset)
    dataset.dip << @dip
    dataset.save
  end

  def set_dip_uuid(uuid)
    @dip.dip_uuid = uuid
  end

  def set_dip_current_path(value)
    @dip.current_path = value
  end

  def set_dip_current_full_path(value)
    @dip.current_full_path = value
  end

  def set_dip_package_size(value)
    @dip.package_size = value
  end

  def set_dip_current_location(value)
    @dip.current_location = value
  end

  def set_dip_resource_uri(value)
    @dip.resource_uri = value
  end

  def set_dip_origin_pipeline(value)
    @dip.origin_pipeline = value
  end

  def set_dip_preflabel(title)
    @dip.preflabel = title
  end

  def set_dip_status(status)
    # TODO check vocab?
    @dip.status = status
  end

  def set_first_requestor(value)
    @dip.first_requestor = value
  end

  #TODO extend this
  def ingest_dip(dip_location)

    location = ENV['DIP_LOCATION'] + '/' + dip_location

    Dir.foreach(location) do |item|
      next if item == '.' or item == '..'
      gw = Dlibhydra::GenericWork.new
      obj_fs = Hydra::Works::FileSet.new
      label = ''
      if item == 'objects'
        Dir.foreach(location + '/objects') do |object|
          next if object == '.' or object == '..'
          gw.preflabel = object
          #obj_fs.preflabel = object
          label = object
          path = location + '/objects/' + object
          file1 = open(path)
          Hydra::Works::UploadFileToFileSet.call(obj_fs, file1)
          obj_fs.save
          gw.members << obj_fs
          gw.save
          @dip.members << gw
          save_dip
        end
      elsif item == 'thumbnails'
        Dir.foreach(location + '/thumbnails') do |thumb|
          next if thumb == '.' or thumb == '..'
          th_id = thumb.sub! '.jpg', ''
          if label.include? th_id
            path = location + '/thumbnails/' + thumb
            file = open(path)
            Hydra::Works::UploadFileToFileSet.call(obj_fs, file)
            obj_fs.save
          end
        end
      else
        fs = Hydra::Works::FileSet.new
        #fs.preflabel = item
        fs.save
        @dip.members << fs
        save_dip
        file = open(location + '/' + item)
        Hydra::Works::UploadFileToFileSet.call(fs, file)
        fs.save
      end

    end

  end

  def get_dip_details(uuid)

    url = ENV['ARCHIVEMATICA_SS_URL']
    conn = Faraday.new(:url => url) do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.response :logger # log requests to STDOUT
      faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
    end

    response = conn.get do |req|
      req.url '/api/v2/file/' + uuid + '/'
      req.headers['Accept'] = 'application/json'
    end
    JSON.parse(response.body)

  end

end