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

  # given a chunk of a local file and a relative path for where it should, write the chunk to the correct place in the temporary deposit 
  def deposit_file_chunk_from_client(filechunk, path, dataset_id, size, first)
    uploaded_filename = path.empty? ? filechunk.original_filename : path
    # if this is a chunked upload and this is the first chunk then we want to write a new file, else we want to append
    if !request.env["HTTP_CONTENT_RANGE"] or request.env["HTTP_CONTENT_RANGE"].starts_with?("bytes 0-")
      write_mode = 'wb'
      # if this is the first file uploaded then delete all existing uploaded files for this dataset before uploading these files
      if first
        delete_deposited_files(dataset_id)
      end
    else
      write_mode = 'ab'
    end
    write_deposit_chunk(filechunk.read, uploaded_filename, dataset_id, size, write_mode)
  end
  
  # given a google file id, a relative path for where it belongs, and a byte range, get the file data from google and write it
  def deposit_file_from_google (file, path, mime_type, dataset_id, size, byte_from, byte_to, first_file)
    service = initialise_api
    filechunk = get_file_from_google(service, file, mime_type, byte_from, byte_to)
    # if it's the first portion of the file, write mode should be "write", else "append"
    if (!byte_from or byte_from.to_i == 0) 
      write_mode = "wb" 
      # if this is the first file uploaded then delete all existing uploaded files for this dataset before uploading these files
      if (first_file == "1")
        delete_deposited_files(dataset_id)
      end
    else
      write_mode = "ab"
    end
    write_deposit_chunk(filechunk.string, path, dataset_id, size, write_mode)
  end

  # given a file chunk and a relative path, write it to the correct place in the temporary deposit
  def write_deposit_chunk (filechunk, path, dataset_id, size, write_mode)
    # work out the base folder into which this file should go
    upload_dir = File.join(@temp_upload_dir, dataset_id, "objects") 
    # work out where to write it - it'll need to go in the temp upload directory for now, and it might have its own relative path
    target_file = sanitise_path(File.join(upload_dir, path))
    target_dir = File.dirname(target_file)
    FileUtils.mkdir_p(target_dir)
    # validate that deposited chunk is OK
    validate_deposit_chunk(filechunk, target_file, upload_dir, dataset_id, write_mode)
    File.open(target_file, write_mode) do |file|
      file.write(filechunk)
    end
    # if we've finished writing the file and it's a zip file, unzip it
    if (File.size(target_file).to_i == size.to_i and File.extname(target_file) == '.zip') then
      begin
        Zip::File.open(target_file) do |zip_file|
          zip_file.each do |entry|
            # extract everything except mac osx guff into a folder with the base-name of the zip file
            unless entry.name.include?("__MACOSX") then
              newpath = File.join(File.dirname(target_file), File.basename(target_file, File.extname(target_file)))
              FileUtils.mkdir_p(newpath)
              entry.extract(File.join(newpath, sanitise_path(entry.name)))
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

  # given a path to be written, remove any bad chars and generally sanitise it before returning it
  def sanitise_path (path)
    # strip any potentially dangerous chars from the file path and remove instances of ".."
    path.gsub(/[^-A-Za-z0-9_ ~.\/\+()]/, "").gsub(/\.+/, ".")
  end

  # check that the uploaded chunk is valid
  def validate_deposit_chunk (filechunk, target_file, upload_dir, dataset_id, write_mode)
    dataset = find_dataset(dataset_id)
    upload_size = (`du -bs #{upload_dir} | tail -n 1 | cut -f 1`).to_i
    #Rails.logger.debug("Upload size is #{upload_size.to_s} bytes")
    # it's a problem if this dataset isn't accepting uploads
    if dataset.aips.size > 0
      raise "Files have already been deposited for this dataset"
    # it's a problem if the filename > 254 chars or the path > 4095 chars
    elsif File.basename(target_file).length > 254 or target_file.length > 4095
      raise "File name or file path is too long"
    # it's a problem if the size of the files already written plus the size of this chunk exceed the max upload size
    elsif upload_size + filechunk.size > 20 * 1024 * 1024 * 1024
      raise "Upload is too large - exceeds maximum upload size"
    # it's a problem if this is a new file and the file already exists
    elsif write_mode == "wb" and File.exists?(target_file)
      raise "The file already exists"
    end
  end

  # delete all files deposited in the AIP - this will be called to clean things up if there was a problem
  #   during file upload
  def delete_deposited_files (dataset_id)
    deposit_upload_dir = File.join(@temp_upload_dir, dataset_id)
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
