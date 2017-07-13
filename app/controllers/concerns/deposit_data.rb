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
  def deposit_file_chunk_from_client(filechunk, path, dataset_id, size)
    uploaded_filename = path.empty? ? filechunk.original_filename : path
    # if this is a chunked upload and this is the first chunk then we want to write a new file, else we want to append
    if !request.env["HTTP_CONTENT_RANGE"] or request.env["HTTP_CONTENT_RANGE"].starts_with?("bytes 0-")
      write_mode = 'wb'
    else
      write_mode = 'ab'
    end
    write_deposit_chunk(filechunk.read, uploaded_filename, dataset_id, size, write_mode)
  end
  
  # given a google file id, a relative path for where it belongs, and a byte range, get the file data from google and write it
  def deposit_file_from_google (file, path, mime_type, dataset_id, size, byte_from, byte_to)
    service = initialise_api
    filechunk = get_file_from_google(service, file, mime_type, byte_from, byte_to)
    # if it's the first portion of the file, write mode should be "write", else "append"
    write_mode = (!byte_from or byte_from.to_i == 0) ? "wb" : "ab"
    write_deposit_chunk(filechunk.string, path, dataset_id, size, write_mode)
  end

  # given a file chunk and a relative path, write it to the correct place in the temporary deposit
  def write_deposit_chunk (filechunk, path, dataset_id, size, write_mode)
    # work out the base folder into which this file should go
    upload_dir = File.join(@temp_upload_dir, dataset_id, "objects") 
    # work out where to write it - it'll need to go in the temp upload directory for now, and it might have its own relative path
    target_file = File.join(upload_dir, path)
    target_dir = File.dirname(target_file)
    FileUtils.mkdir_p(target_dir)
    File.open(target_file, write_mode) do |file|
      file.write(filechunk)
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
