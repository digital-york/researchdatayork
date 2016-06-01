# app/controllers/concerns/search_pure.rb
module DepositData
  extend ActiveSupport::Concern

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

  def deposit_files(file)
    # TODO Allow multiple files
    # TODO Unpack zip files
    # TODO Google Drive implementation
    FileUtils.chmod 0644, file.tempfile
    FileUtils.mv(file.tempfile, @dir_aip + file.original_filename)
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