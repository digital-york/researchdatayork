class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show]
  include Dlibhydra
  include CreateDataset
  include CreateDip
  include ShowDip

  # GET /datasets
  # GET /datasets.json
  def index
  end

  # GET /datasets/1
  # GET /datasets/1.json
  # GET /datasets/1.zip
  def show
    # a few different cases to deal with here:
    #  - user wants the dataset but hasn't provided an email address
    #  - user wants the dataset and has provided an email address
    #  - user wants a zip download of the dataset files
    @dataset = find_dataset(params[:id])
    @dip_files = dip_directory_structure(@dataset)
    if params[:request]
      # handle case where user has just provided an email address
      if params[:request][:email].include? '@'
        flash.now[:notice] = 'Thank you. We will send you an email when the data is available.'
        create_dip(@dataset)
        requestor_email(params[:request][:email])
        # send an email to RDM team to tell them that data has been requested
        RdMailer.notify_rdm_team_about_request(params[:id], params[:request][:email]).deliver_later
      # handle case where user hasn't provided an email address
      else
        flash.now[:error] = 'Please provide a full email address.'
      end
    # handle case where user has requested zip download
    elsif request.format.zip?
      # log the download time and increment the download count
      log_download(@dataset)
      # create a zip file 
      zip_file_stream = dip_as_zip_filestream(@dataset)
    end
    respond_to do |format|
      format.html { render :show, notice: @notice }
      format.json { render :show, status: :created, location: @deposit }
      format.zip { send_data zip_file_stream.read, filename: 'dataset.zip' }
    end
  end

  # GET /datasets/1/documentation
  # return the submission documentation (probably readme.txt) for the given dataset if it exists
  def documentation
    dataset = find_dataset(params[:id])
    @readme = dataset.readme rescue ""
    respond_to do |format|
      format.text
    end
  end

  # GET /datasets/1/filedownload/1
  # given a dataset id and a file id, update the dataset's last_access and number_of_downloads fields and redirect the user to the file they want
  def filedownload
    # get the dataset
    dataset = find_dataset(params[:id])
    # if the user is allowed to download this file (i.e. they're an admin or it's an 'open' dataset)
    if (current_user && current_user.admin?) || (dataset.dc_access_rights[0] == 'Open') then
      # log the last_access time and increment the number_of_downloads for this dataset
      log_download(dataset)
      # get the dip files structure array
      dip_files = dip_directory_structure(dataset)
      # give the user the file from the dip store (no longer storing files in hydra as they might be massive)
      send_file(dip_files[params[:fileid]][:file_path_abs])
    else
      render :plain => "You do not have permission to download this file"
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dataset
    @request = Request.new
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def dataset_params
    params.fetch(:dataset, {})
    params.permit(:request, :email)
  end

  # given a dataset, update its last_access timestamp to the current date/time and increment the number_of_downloads field
  def log_download(dataset)
    # only log if the user is a human, not a bot (e.g. googlebot) - uses the 'browser' gem
    if !browser.bot? then
      dataset.last_access = Time.now.utc.iso8601
      dataset.number_of_downloads = dataset.number_of_downloads.to_i + 1
      dataset.save
    end
  end

end
