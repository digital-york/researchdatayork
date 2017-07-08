# app/controllers/concerns/deposit_data.rb
module DepositData
  extend ActiveSupport::Concern

  require 'http_headers'
  require 'zip'

  included do

  end

  def new_deposit(dataset_id,aip_id)
    @dir_dataset = File.join(@deposit_dir, dataset_id)
    @dir_aip = File.join(@dir_dataset, aip_id)
    make_data_directories
  end

  def make_data_directories
    FileUtils.mkdir_p(@dir_dataset)
    FileUtils.mkdir_p(@dir_aip)
  end

  def metadata_dir
    File.join(@temp_upload_dir, @dataset.id, "metadata")
  end

  def submission_documentation_dir
    File.join(metadata_dir, "submissionDocumentation")
  end

  # given a string of text, write it to a readme.txt file in the submission documentation folder
  def deposit_submission_documentation(text)
    # the text should be written to @dir_aip/metadata/submissionDocumentation/readme.txt
    #   according to
    #   https://www.archivematica.org/en/docs/archivematica-1.4/user-manual/transfer/transfer/#create-submission
    target_dir = submission_documentation_dir
    target_file = File.join(target_dir, "readme.txt")
    FileUtils.mkdir_p(target_dir)
    File.open(target_file, "w") do |output|
      output.write text
    end
  end

  def add_metadata(metadata)
    require 'json'
    json = JSON.generate(JSON.parse metadata.gsub('=>', ':'))
    # metadata.json needs to go in submission documentation dir
    target_dir = submission_documentation_dir
    FileUtils.mkdir_p(target_dir)
    target_file = File.join(target_dir, "metadata.json")
    File.write(target_file, json)
  end

  # given an array of files on the user's client machine, upload them, unzip them if they're zipped,
  # and store them in the transfer folder
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
        target_file = File.join(@dir_aip, "objects", uploaded_filename)
        target_dir = File.dirname(target_file)
        # create any directories in target_dir that don't already exist
        FileUtils.mkdir_p(target_dir)
        # move this uploaded file into place (into target_dir)
        FileUtils.chmod 0644, f.tempfile
        FileUtils.mv(f.tempfile, target_file)
      end
    end
  end

  def deposit_files_from_client2(files, path, dataset_id, size)
    # work out the base folder into which this upload should go
    upload_dir = File.join(@temp_upload_dir, dataset_id, "objects") 
    files.each do |f|
      # the file name will either be in "original_filename" for normal uploads, or in "path" for directory uploads
      uploaded_filename = path.empty? ? f.original_filename : path
      # work out where to write it - it'll need to go in the temp upload directory for now, and it might have its own relative path
      target_file = File.join(upload_dir, uploaded_filename)
      target_dir = File.dirname(target_file)
      FileUtils.mkdir_p(target_dir)
      # if this is a chunked upload and this is the first chunk then we want to write a new file, else we want to append
      if !request.env["HTTP_CONTENT_RANGE"] or request.env["HTTP_CONTENT_RANGE"].starts_with?("bytes 0-")
        write_mode = 'wb'
      else
        write_mode = 'ab'
      end
      File.open(target_file, write_mode) do |file|
        file.write(f.read)
      end
      # if we've finished writing the file and it's a zip file, unzip it
      if (File.size(target_file).to_i == size.to_i and File.extname(target_file) == '.zip') then
        begin
          Zip::File.open(target_file) do |zip_file|
            zip_file.each do |entry|
              # extract everything except mac osx guff
              unless entry.name.include?("__MACOSX") then
                entry.extract(File.join(File.dirname(target_file), entry.name))
              end
            end
          end
          # delete zip file after extracting
          File.delete(target_file)
        rescue
          # don't do anything about bad zips
        end
      end
    end
  end

  def deposit_files_from_cloud(files, paths, mime_types)
    # initialise the google api
    service = initialise_api
    # for each file (and path) selected by the user
    files.zip(paths, mime_types).each do |file, path, mime_type|
      # download the file from Google
      f = get_file_from_google(service, file, mime_type)
      # if the file was a google document it will have been exported to a specific format
      #   and may require an extra file extension
      if google_docs_mimetypes.has_key?(mime_type)
        path = path + google_docs_mimetypes[mime_type]["export_extension"] unless
            path.ends_with?(google_docs_mimetypes[mime_type]["export_extension"])
      end
      # work out where this file should be uploaded to
      target_file = File.join(@dir_aip, "objects", path)
      target_dir = File.dirname(target_file)
      FileUtils.mkdir_p(target_dir)
      File.open(target_file, "wb") do |output|
        output.write f.string
      end
    end
  end

  # delete all files deposited in the AIP - this will be called to clean things up if there was a problem
  #   during file upload
  def delete_deposited_files
    deposit_upload_dir = File.join(@temp_upload_dir, @dataset.id)
    if Dir.exists?(deposit_upload_dir)
      FileUtils.rm_rf(deposit_upload_dir)
    end
    if @dir_dataset
      FileUtils.rm_rf(@dir_dataset)
    end
  end

  def add_submission_documentation
    unless Dir.exists? (dir + 'submissionDocumentation')
      FileUtils.mkdir(dir + 'submissionDocumentation')
    end
  end

end
