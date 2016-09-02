# app/controllers/concerns/search_pure.rb
module CreateDip
  extend ActiveSupport::Concern

  included do
    # ???
    attr_reader :dip
  end

  def create_dip(dataset)
    @dip = dataset.aips[0]
    @dip.dip_uuid = 'tbc' # so that we can call datasets.dips
  end

  def save_dip
    @dip.save
  end

  def update_dip(id, uuid)
    dataset = Dlibhydra::Dataset.find(id)
    @dip = dataset.aips[0]
    dip_info = get_dip_details(uuid)
    # TODO some error handling here
    ingest_dip(dip_info['current_path'])
    set_dip_current_path(dip_info['current_path'])
    set_dip_uuid(dip_info['uuid'])
    set_dip_status(dip_info['status'])
    set_dip_size(dip_info['size'])
    set_dip_current_location(dip_info['current_location']) # api location
    set_dip_resource_uri(dip_info['resource_uri']) # api uri
    set_dip_size(dip_info['size'])
    set_dip_origin_pipeline(dip_info['origin_pipeline'])
    save_dip

    'AIP updated with dissemination objects'
  end

  def set_dip_uuid(uuid)
    @dip.dip_uuid = uuid
  end

  def set_dip_current_path(value)
    @dip.dip_current_path = value
  end

  def set_dip_resource_uri(value)
    @dip.dip_resource_uri = value
  end

  def set_dip_size(value)
    @dip.dip_size = value
  end

  def set_dip_current_location(value)
    @dip.dip_current_location = value
  end

  def set_dip_origin_pipeline(value)
    @dip.origin_pipeline = value
  end

  def set_dip_status(status)
    @dip.dip_status = status
  end

  def set_requestor_email(value)
    unless @dip.requestor_email.include? value
      emails = @dip.requestor_email.clone
      emails << value
      @dip.requestor_email = emails
    end
  end
  
  # inside the dip location folder, there will be:
  # - a folder called "objects" containing the actual files of the dip
  # - a folder called "thumbnails" containing thumbnails for each file in the dip
  # - a file called "METS.xxxx.xml"
  # - a file called "ProcessingMCP.xml"
  # Need to create a FileSet for METS.xxxx.xml, a FileSet for Processing.MCP.xml, and a FileSet for each actual file in the dip
  # (which will consist of a primary file (in "objects") and an additional file (in "thumbnails"))
  def ingest_dip(dip_location)
    # uncomment the next 2 lines, and add 2nd parameter "dataset_id" to the function spec in order to call this method standalone
    #dataset = Dlibhydra::Dataset.find(dataset_id)
    #@dip = dataset.aips[0]
    location = File.join(ENV['DIP_LOCATION'], dip_location)
    # for each file/folder in the dip location
    Dir.foreach(location) do |item|
      # if it's the "objects" folder
      if File.directory?(File.join(location, item)) and item == "objects"
        # for each file in the "objects" folder
        Dir.foreach(File.join(location, item)) do |object|
          # skip any directories inside the objects folder
          next if File.directory?(File.join(location, item, object))
          # create a new FileSet
          obj_fs = Dlibhydra::FileSet.new
          # add this file to the FileSet
          obj_fs.preflabel = object
          path = File.join(location, item, object)
          f = open(path)
          Hydra::Works::UploadFileToFileSet.call(obj_fs, f)
          # get the first 36 characters of the filename - the "thumbnail" and "ocr text" corresponding to this file will have this prefix
          prefix = object[0..35] 
          # find the "thumbnail" that corresponds to this file (it'll have the same filename prefix) if it exists and add it to the FileSet
          thumbnail_file = prefix + ".jpg"
          thumbnail_path = File.join(location, "thumbnails", thumbnail_file)
          if File.file?(thumbnail_path)
            f2 = open(thumbnail_path)
            Hydra::Works::AddFileToFileSet.call(obj_fs, f2, :thumbnail, update_existing: false)
          end
          # find the OCR file that corresponds to this file if it exists and add it to the FileSet
          ocrfile = prefix + ".txt"
          ocrfile_path = File.join(location, "OCRfiles", ocrfile)
          if File.file?(ocrfile_path)
            f3 = open(ocrfile_path)
            Hydra::Works::AddFileToFileSet.call(obj_fs, f3, :extracted_text, update_existing: false)
          end
          # add this FileSet to the dip
          obj_fs.save
          @dip.members << obj_fs
          save_dip
        end
      # otherwise, if it's a file (not a folder)
      elsif File.file?(File.join(location, item))
        # create a new FileSet
        obj_fs = Dlibhydra::FileSet.new
        # add this file to the FileSet
        obj_fs.preflabel = item
        f = open(File.join(location, item))
        Hydra::Works::UploadFileToFileSet.call(obj_fs, f)
        # add this FileSet to the dip
        obj_fs.save
        @dip.members << obj_fs
        save_dip
      end
    end
  end

  def ingest_dip_orig(dip_location)
    location = ENV['DIP_LOCATION'] + '/' + dip_location
    gw = Dlibhydra::GenericWork.new
    #obj_fs = Dlibhydra::FileSet.new
    label = ''
    Dir.foreach(location) do |item|
      next if item == '.' or item == '..' or item == '.DS_Store'
      if item == 'objects'
        Dir.foreach(location + '/objects') do |object|
          # TODO is there more here I should exclude?
          next if object == '.' or object == '..' or object == '.DS_Store'
          obj_fs = Dlibhydra::FileSet.new
          gw.preflabel = object
          obj_fs.preflabel = object
          label = object
          path = location + '/objects/' + object
          puts path
          file1 = open(path)
          # this is the service file but doesn't appear to be supported in
          # https://github.com/projecthydra/hydra-works/blob/master/lib/hydra/works/models/concerns/file_set/contained_files.rb
          Hydra::Works::UploadFileToFileSet.call(obj_fs, file1)
          obj_fs.save
          Rails.logger.debug("obj_fs: #{obj_fs.files.inspect}") # FAM DEBUG
          gw.members << obj_fs
          gw.save
          @dip.members << gw
          save_dip
        end
      end
    end
    Rails.logger.debug("gw = #{gw.members.inspect}")
    Dir.foreach(location) do |item|
      next if item == '.' or item == '..' or item == '.DS_Store'
      if item == 'thumbnails'
        Dir.foreach(location + '/thumbnails') do |thumb|
          next if thumb == '.' or thumb == '..' or thumb == '.DS_Store'
          th_id = thumb.sub! '.jpg', ''
          puts th_id
          if label.include? th_id
            path = location + '/thumbnails/' + thumb + '.jpg'
            file = open(path)
#            Hydra::Works::AddFileToFileSet.call(obj_fs, file,:thumbnail,update_existing: false)
#            obj_fs.save
          end
        end
      elsif item == 'OCRfiles'
        Dir.foreach(location + '/OCRfiles') do |ocr|
          next if ocr == '.' or ocr == '..' or ocr == '.DS_Store'
          ocr_id = ocr.sub! '.txt', ''
          puts label
          puts ocr_id
          if label.include? ocr_id
            path = location + '/OCRfiles/' + ocr + '.txt'
            file = open(path)
            puts path
#            Hydra::Works::AddFileToFileSet.call(obj_fs, file,:extracted_text,update_existing: false)
#            obj_fs.save
          end
        end
      else
        next if item == '.' or item == '..' or item == '.DS_Store'
        begin
          fs = Dlibhydra::FileSet.new
          fs.preflabel = item
          fs.save
          @dip.members << fs
          file = open(location + '/' + item)
          Hydra::Works::UploadFileToFileSet.call(fs, file)
          save_dip
          fs.save
        rescue
          # TODO log errors
        end
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

    params = {
        'username' => ENV['ARCHIVEMATICA_SS_USER'] ,
        'api_key' => ENV['ARCHIVEMATICA_SS_API_KEY']
    }

    response = conn.get do |req|
      req.url '/api/v2/file/' + uuid + '/'
      req.headers['Accept'] = 'application/json'
      req.params = params
    end
    JSON.parse(response.body)

  end

end
