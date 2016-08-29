class DepositsController < ApplicationController
  helper DepositsHelper
  before_action :set_deposit, only: [:show, :edit, :update, :destroy]
  include Dlibhydra
  include Puree
  include SearchPure
  include SearchSolr
  include CreateDataset
  include CreateAip
  include DepositData
  include ReingestAip
  include CreateDip
  include Googledrive
  helper_method :connected_to_google_api?  # defined in Googledrive module so view can know whether or not to call google api

  #20ee85c3-f53c-4ab6-8e50-270b0ddd3686
  # there is a problem with project
  #e3f87d05-ab3c-49ef-a69d-0a9805b77d2f - live object with project

  # GET /deposits
  # GET /deposits.json
  def index

    # This is a basic ActiveRecord object. It is never saved.
    @deposit = Deposit.new

    # Get number of results to return
    num_results = get_number_of_results('has_model_ssim:"Dlibhydra::Dataset"')
    response = nil
    # Get all dataset records from Solr
    unless num_results == 0
      response = solr_query_short('has_model_ssim:"Dlibhydra::Dataset"','pure_uuid_tesim',num_results)
    end

    if params[:refresh] == 'true'
      if params[:refresh_num]
        c = get_uuids(params[:refresh_num])
        get_datasets_from_collection(c,response)
      elsif params[:refresh_date]
        c = get_uuids_created_from_tonow(params[:refresh_date])
        get_datasets_from_collection(c,response)
        c = get_uuids_modified_from_tonow(params[:refresh_date])
        get_datasets_from_collection(c,response)
      else
        c = get_uuids
        get_datasets_from_collection(c,response)
      end
    end

    # check if we have it in solr, if not create a dataset
    num_results = get_number_of_results('has_model_ssim:"Dlibhydra::Dataset"')

    unless num_results  == 0
      response = solr_query_short('has_model_ssim:"Dlibhydra::Dataset"',
                                  'id,pure_uuid_tesim,preflabel_tesim,wf_status_tesim,date_available_tesim,
                                    access_rights_tesim,creator_ssim,pureManagingUnit_ssim,
                                    pure_link_tesim,doi_tesim,pure_creation_tesim',
                                  num_results)
    end

    if response.nil?
      @deposits = []
    else
      @deposits = response
    end
  end

  # GET /deposits/1
  # GET /deposits/1.json
  def show

    @notice = ''

    if params[:deposit]
      # if the user uploaded local file(s), they will be in params[:deposit][:file], if cloud file(s), they'll be in params[:selected_files]  
      if params[:deposit][:file] or params[:selected_files]
        @aip = new_aip
        set_user_deposit(@dataset,params[:deposit][:readme])
        new_deposit(@dataset.id,@aip.id)
        add_metadata(@dataset.for_indexing)
        # handle upload of client side file(s)
        if params[:deposit][:file]
          deposit_files_from_client(params[:deposit][:file])
        end
        if params[:selected_files] and params[:selected_paths] and params[:selected_mimetypes]
          deposit_files_from_cloud(params[:selected_files], params[:selected_paths], params[:selected_mimetypes])
        end
        # TODO write metadata.json
        # TODO add submission info
        @notice = 'The deposit was successful.'
        @dataset = nil
      else
        @notice = "You didn't deposit any data!"
      end
    end
    respond_to do |format|
      format.html { render :show, notice: @notice }
      format.json { render :show, status: :created, location: @deposit }
    end
  end

  # GET /deposits/new
  def new
    # This is a basic ActiveRecord object. It is never saved.
    @deposit = Deposit.new
  end

  # GET /deposits/1/edit
  def edit
    # Use this for editing datasets
  end

  # POST /deposits
  # POST /deposits.json
  def create

    # If a pure uuid has been supplied
    if params[:deposit][:pure_uuid]

      # Check solr for a dataset object
      uuid = params[:deposit][:pure_uuid]
      query = 'pure_uuid_tesim:"' + uuid + '""'
      response = solr_query_short(query,'id,pure_uuid_tesim',1)

      # If there is no dataset, create one
      # Otherwise use existing dataset object
      if response['numFound'] == 0
        notice = 'PURE data was successfully added.'
        @dataset = new_dataset
      else
        notice = 'Dataset object already exists for this PURE UUID. Metadata updated.'
        @dataset = find_dataset(response['docs'][0]['id'])
      end

      # Fetch metadata from pure and update the dataset
      d = get_pure_dataset(uuid)
      set_metadata(@dataset,d)

      respond_to do |format|
        format.html { redirect_to deposits_path, notice: notice }
        # format.json { render :index, status: :created, location: @dataset }
      end
    else
      # TODO Create new dataset from scratch
      notice = 'The deposit was successful.'

      respond_to do |format|
        format.html { render :show, notice: notice }
        # format.json { render :show, status: :created, location: @deposit }
      end
    end
  end

  # PATCH/PUT /deposits/1
  # PATCH/PUT /deposits/1.json
  def update
    # TODO
    respond_to do |format|
      if @deposit.update(deposit_params)
        format.html { redirect_to @deposit, notice: 'deposit was successfully updated.' }
        format.json { render :show, status: :ok, location: @deposit }
      else
        format.html { render :edit }
        format.json { render json: @deposit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deposits/1
  # DELETE /deposits/1.json
  def destroy
    # TODO
    @deposit.destroy
    respond_to do |format|
      format.html { redirect_to deposits_url, notice: 'deposit was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # Search
  def search
    # TODO
  end

  # Reingest
  def reingest
    message = reingest_aip('objects',params[:id])
    respond_to do |format|
      format.html { redirect_to deposits_url, notice: message['message'] }
      format.json { head :no_content }
    end
  end

  def dipuuid
    message = update_dip(params[:deposit][:id],params[:deposit][:dipuuid])
    respond_to do |format|
      format.html { redirect_to deposits_url, notice: message }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_deposit
    @deposit = Deposit.new
    @dataset = Dlibhydra::Dataset.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def deposit_params
    params.permit(:deposit, :uuid, :file, :submission_doco,
                  :title, :refresh, :refresh_num,
                  :pure_uuid, :readme, :access,
                  :embargo_end, :available, :dipuuid)
  end

  private

  # Given a Puree collection, get each dataset
  # Create a new Hydra dataset, or update an existing one
  # Ignore data not published by the given publisher
  def get_datasets_from_collection(c, response)
    c.uuid.each do |uuid|
      d = get_pure_dataset(uuid)
      unless d.publisher.exclude? ENV['PUBLISHER']
        if response != nil and response.to_s.include? uuid
          r = solr_query_short('pure_uuid_tesim:"' + uuid + '"','id',1)
          local_d = find_dataset(r['docs'][0]['id'])
        else
          local_d = new_dataset
        end
        set_metadata(local_d,d)
      end
    end
    end

  end
