# app/controllers/concerns/search_pure.rb
module DepositData
  extend ActiveSupport::Concern

  require 'http_headers'
  require 'zip'

  included do

  end

  def new_deposit(dataset_id,aip_id)
    @dir_dataset = ENV['TRANSFER_LOCATION'] + '/' + dataset_id
    @dir_aip = @dir_dataset + '/' + aip_id + '/'
    make_data_directories
  end

  def make_data_directories
    unless Dir.exists? (@dir_dataset)
      FileUtils.mkdir(@dir_dataset)
    end
    unless Dir.exists? (@dir_aip)
      FileUtils.mkdir(@dir_aip)
    end
  end

  # given an array of files on the user's client machine, upload them, unzip them if they're zipped, and store them in the AIP folder 
  def deposit_files_from_client(files)
    # handle each of the uploaded files
    files.each do |f|
      # get the uploaded filename (including its path in the case of directory upload)
      h = HttpHeaders.new(f.headers)
      uploaded_filename = h.content_disposition.match(/filename=(\"?)(.+)\1/)[2] 
      # if it's a .zip file, extract its contents to @dir_aip
      if File.extname(uploaded_filename) == '.zip' then
        Zip::File.open(f.tempfile) do |zip_file|
          zip_file.each do |entry|
            # extract everything except mac osx guff
            unless entry.name.include?("__MACOSX") then
              entry.extract(File.join(@dir_aip, entry.name))
            end
          end
        end
      # otherwise, not a zip file, just bung this file in the @dir_aip folder
      else
        # work out where this uploaded file should go (in order to preserve the structure of the upload)
        target_file = File.join(@dir_aip, uploaded_filename)
        target_dir = File.dirname(target_file)
        # create any directories in target_dir that don't already exist
        FileUtils.mkdir_p(target_dir)
        # move this uploaded file into place (into target_dir)
        FileUtils.chmod 0644, f.tempfile
        FileUtils.mv(f.tempfile, target_file)
      end
    end
  end

  # given a hash of Google Drive files selected by the user, download them to the AIP folder
  def deposit_files_from_cloud(files)
    retriever = BrowseEverything::Retriever.new
    files.each do |index, file|
      target_file = File.join(@dir_aip, file['file_name'])
      retriever.download(file, target_file) do |filename, retrieved, total|
        # could potentially output download progess here
      end
    end
  end

  def add_metadata(metadata)
    require 'json'
    # TODO eval is a bit dodgy, consider replacing
    File.write(@dir_aip + 'metadata.json', eval("[#{metadata}]").to_json)
  end

  def add_submission_documentation
    unless Dir.exists? (dir + 'submissionDocumentation')
      FileUtils.mkdir(dir + 'submissionDocumentation')
    end
  end

end
