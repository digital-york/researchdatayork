class DepositsController < ApplicationController
  helper DepositsHelper
  before_action :set_deposit, only: [:show, :edit, :update, :destroy]

  # only show page is visible
  # TODO some kind of token based visibility
  before_action :authenticate_user!, except: [:show]
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
  helper_method :connected_to_google_api? # defined in Googledrive module so view can know whether or not to call google api

  #20ee85c3-f53c-4ab6-8e50-270b0ddd3686
  # there is a problem with project
  #e3f87d05-ab3c-49ef-a69d-0a9805b77d2f - live object with project

  # GET /deposits
  # GET /deposits.json
  def index

    # This is an empty ActiveRecord object. It is never saved.
    @deposit = Deposit.new

    # setup base query parameters
    q = 'has_model_ssim:"Dlibhydra::Dataset"'
    ids = []
    fq = []
    no_results = false

    unless params[:q].nil?
      # TODO or search for multiple words etc.
      unless params[:q] == ''
        q += ' and for_indexing_tesim:' + params[:q]
      end

      unless params[:new].nil?
        fq << '!wf_status_tesim:*' # no workflow statuses
        fq << '!member_ids_ssim:*' # no packages
      end

      unless params[:doi].nil?
        if params[:doi] == 'doi'
          q += 'and doi_tesim:*'
        elsif params[:doi] == 'nodoi'
          fq << '!doi_tesim:*'
        end
      end

      unless params[:status].nil?
        params[:status].each do |s|
          q += ' and wf_status_tesim:' + s + ''
        end
      end

      unless params[:aip_status].nil?
        params[:aip_status].each do |aipstatus|

          if aipstatus == 'noaip'
            fq << '!member_ids_ssim:*'
          else
            fq << 'member_ids_ssim:*'
            num_results = get_number_of_results('has_model_ssim:"Dlibhydra::Dataset" and member_ids_ssim:*',)
            if num_results == 0
              fq << 'member_ids_ssim:*'
            else
              r = solr_filter_query('has_model_ssim:"Dlibhydra::Dataset" and member_ids_ssim:*', [],
                                    'id,member_ids_ssim', num_results)
              if aipstatus == 'uploaded'
                status_query = 'aip_status_tesim:UPLOADED'
              elsif aipstatus == 'inprogress'
                status_query = 'aip_status_tesim:(COMPLETE or PROCESSING or "Not Yet Processed")'
              elsif aipstatus == 'problem'
                status_query = 'aip_status_tesim:(ERROR or FAILED or USER_INPUT)'
              end
              r['docs'].each do |dataset|
                dataset['member_ids_ssim'].each do |aip|
                  num_results = get_number_of_results('id:'+ aip, status_query)
                  if num_results == 0
                    fq << '!id:' + dataset['id']
                  else
                    ids << dataset['id']
                  end
                end
              end
            end
          end
        end
      end
    end

    unless params[:dip_status].nil?
      no_results = true
      params[:dip_status].each do |dipstatus|
        num_results = get_number_of_results('has_model_ssim:"Dlibhydra::Dataset" and member_ids_ssim:*',)
        if num_results == 0
          fq << 'member_ids_ssim:*'
        else
          r = solr_filter_query('has_model_ssim:"Dlibhydra::Dataset" and member_ids_ssim:*', [],
                                'id,member_ids_ssim', num_results)
          r['docs'].each do |dataset|
            dataset['member_ids_ssim'].each do |dip|
              if dipstatus == 'APPROVE' or dipstatus == 'UPLOADED'
                num_results = get_number_of_results('id:'+ dip +' and dip_status_tesim:' + dipstatus, [])
                if num_results == 0
                  fq << '!id:' + dataset['id']
                else
                  ids << dataset['id']
                  no_results = false
                end
              elsif dipstatus == 'waiting'
                num_results = get_number_of_results('id:'+ dip, ['requestor_email_tesim:*', '!dip_status_tesim:*'])
                if num_results == 0
                  fq << '!id:' + dataset['id']
                else
                  ids << dataset['id']
                  no_results = false
                end
              else
                num_results = get_number_of_results('id:'+ dip +' and dip_uuid_tesim:*')
                unless num_results == 0
                  no_results = false
                  fq << '!id:' + dataset['id']
                end
              end
            end
          end
        end
      end
    end

    unless ids.empty?
      extra_fq = 'id:('
      ids.each_with_index do |i, index|
        if index == ids.length - 1
          extra_fq += "#{i}"
        else
          extra_fq += "#{i} or "
        end

      end
      extra_fq += ')'
      fq << extra_fq
    end

    if no_results
      response = nil
    else
      num_results = get_number_of_results(q, fq)
      unless num_results == 0
        response = solr_filter_query(q, fq,
                                     'id,pure_uuid_tesim,preflabel_tesim,wf_status_tesim,date_available_tesim,
                                    access_rights_tesim,creator_ssim,pureManagingUnit_ssim,
                                    pure_link_tesim,doi_tesim,pure_creation_tesim, wf_status_tesim',
                                     num_results)
      end
    end

    if params[:refresh] == 'true'
      if params[:refresh_num]

        c = get_uuids(params[:refresh_num])
        get_datasets_from_collection(c, response)

      elsif params[:refresh_from]

        c = get_uuids_created_from_tonow(params[:refresh_from])
        uuids = get_datasets_from_collection(c, response)

        # uuids is a list of new datasets created after the solr query
        # these are used to ensure we don't create duplicates
        c = get_uuids_modified_from_tonow(params[:refresh_from])
        get_datasets_from_collection(c, response, uuids)

      else
        c = get_uuids
        get_datasets_from_collection(c, response)
      end
    end

    if response.nil?
      @deposits = []
    else
      @deposits = response
    end
    respond_to do |format|
      format.html { render :index }
      # format.json { render :index, status: :created, location: @dataset }
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
        set_user_deposit(@dataset, params[:deposit][:readme])
        new_deposit(@dataset.id, @aip.id)
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
    if params[:deposit]
      if params[:deposit][:pure_uuid]

        # Check solr for a dataset object
        uuid = params[:deposit][:pure_uuid]
        d = get_pure_dataset(uuid)

        unless d.nil?
          query = 'pure_uuid_tesim:"' + d['uuid'] + '""'
          response = solr_query_short(query, 'id,pure_uuid_tesim', 1)

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

          set_metadata(@dataset, d)
        end

        respond_to do |format|
          format.html { redirect_to deposits_path, notice: notice }
          # format.json { render :index, status: :created, location: @dataset }
        end
      else
        @deposit = Deposit.new
        @deposit.id = params[:deposit][:id].to_s
        @deposit.status = params[:deposit][:status]
        @dataset_id = params[:deposit][:id].to_s
        d = Dlibhydra::Dataset.find(@dataset_id)
        d.wf_status = params[:deposit][:status]
        d.save

        respond_to do |format|
          #format.html { render :show, notice: notice }
          format.js {}
          #format.json { render :show, status: :created, location: @deposit }
        end
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
    message = reingest_aip('objects', params[:id])
    respond_to do |format|
      format.html { redirect_to deposits_url, notice: message['message'] }
      format.json { head :no_content }
    end
  end

  def dipuuid
    message = update_dip(params[:deposit][:id], params[:deposit][:dipuuid])
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
                  :title, :refresh, :refresh_num, :refresh_from,
                  :pure_uuid, :readme, :access,
                  :embargo_end, :available, :dipuuid, :status, :release, :q, :aip_status, :dip_status, :doi)
  end

  private

  # Given a Puree collection (an array of hashes), get each dataset
  # Create a new Hydra dataset, or update an existing one
  # Ignore data not published by the given publisher
  def get_datasets_from_collection(c, response, new_uuids=[])

    c.each do |d|
      unless d['publisher'].exclude? ENV['PUBLISHER']
        if response != nil and (new_uuids.include? d['uuid'] or response.to_s.include? d['uuid'])
          r = solr_query_short('pure_uuid_tesim:"' + d['uuid'] + '"', 'id', 1)
          local_d = find_dataset(r['docs'][0]['id'])
        else
          new_uuids << d['uuid']
          local_d = new_dataset
        end

        set_metadata(local_d, d)
      end
    end
    new_uuids
  end

end
