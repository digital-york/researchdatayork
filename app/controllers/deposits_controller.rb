class DepositsController < ApplicationController
  helper DepositsHelper
  before_action :set_deposit, only: [:show, :edit, :update, :destroy]
  before_action :set_globals

  # TODO some kind of token based visibility

  # enforce some access control rules. All methods require the end user to be logged in
  before_action :authenticate_user!
  # and most method (all except 'show' - the deposit upload page) require the end user to be an administrator
  before_action :verify_is_admin, except: [:show]

  include Dlibhydra
  include Puree
  include SearchPure
  include SearchSolr
  include CreateDataset
  include CreateAip
  include DepositData
  include ReingestAip
  include CreateDip
  include Exceptions
  include Googledrive
  helper_method :connected_to_google_api? # defined in Googledrive module so view can know whether or not to call google api

  # given a number of pure records to refresh, or a number of days to refresh from, refresh the datasets from pure
  def refresh_from_pure (refresh_num = nil, refresh_from = nil)
    # Get number of results to return
    num_datasets = get_number_of_results('has_model_ssim:"Dlibhydra::Dataset"')
    solr_response = nil
    # Get all dataset records from Solr
    unless num_datasets == 0
      solr_response = solr_query_short('has_model_ssim:"Dlibhydra::Dataset"','pure_uuid_tesim',num_datasets)
    end
    c = nil
    if refresh_num
      c = get_uuids(refresh_num)
      get_datasets_from_collection(c, solr_response)
    elsif refresh_from
      c = get_uuids_created_from_tonow(refresh_from)
      uuids = get_datasets_from_collection(c, solr_response)
      # uuids is a list of new datasets created after the solr query
      # these are used to ensure we don't create duplicates
      c = get_uuids_modified_from_tonow(refresh_from)
      get_datasets_from_collection(c, solr_response, uuids)
    else
      c = get_uuids
      get_datasets_from_collection(c, solr_response)
    end
    # return a list of all the refreshed pure records
    c.map{|x| x["uuid"]}
  end

  # GET /deposits
  # GET /deposits.json
  def index

    # This is an empty ActiveRecord object. It is never saved.
    @deposit = Deposit.new
    @refreshed = []

    # if user asked for new/updated datasets, fetch or update them
    if params[:refresh] == 'true'
      @refreshed = refresh_from_pure(params[:refresh_num], params[:refresh_from])
    end

    # setup base query parameters
    q = 'has_model_ssim:"Dlibhydra::Dataset"'
    ids = []
    fq = []
    no_results = false

    unless params[:q].nil?
      # TODO or search for multiple words etc.
      unless params[:q] == ''
        fq << 'for_indexing_tesim:"' + params[:q] + '" OR restriction_note_tesim:"' + params[:q] + '" OR id:"' + params[:q] + '"'
      end

      unless params[:new].nil?
        fq << '!wf_status_tesim:*' # no workflow statuses
        fq << '!member_ids_ssim:*' # no packages (was '') 
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

    # SORTING AND PAGING
    @results_per_page = 10
    # set up an array for holding the sort clause - default to sorting on created date
    solr_sort_fields = ["id asc"]
    if !params[:sort]
      params[:sort] = 'created'
      params[:sort_order] = 'desc'
    end
    # if a valid sort parameter was given
    if params[:sort] and ["access", "created", "available"].include?(params[:sort])
      solr_sort = ''
      # set up the appropriate solr sort field
      if params[:sort] == 'access'
        solr_sort = 'access_rights_tesi'
      elsif params[:sort] == 'created'
        solr_sort = 'pure_creation_ssi'
      elsif params[:sort] == 'available'
        solr_sort = 'date_available_ssi'
      end
      # if a valid sort direction was given, include that in the sort clause
      if params[:sort_order] and ["asc","desc"].include?(params[:sort_order]) then
        solr_sort += ' ' + params[:sort_order]
      else
        solr_sort += ' asc'
      end
      # prepend it to the sort clause array
      solr_sort_fields = solr_sort_fields.unshift(solr_sort)
    end
    # handle paging - default to the first page of results
    @current_page = 1
    # if a valid paging parameter was given
    if params[:page] and params[:page].match(/^\d+$/)
      # use it to get the requested page
      @current_page = params[:page].to_i
    end

    if no_results
      response = nil
    else
      num_results = get_number_of_results(q, fq)
      unless num_results == 0
        response = solr_filter_query(q, fq,
                                     'id,pure_uuid_tesim,title_tesim,wf_status_tesim,date_available_tesim,
                                    dc_access_rights_tesim,creator_value_ssim,managing_organisation_value_ssim,
                                    pure_link_tesim,doi_tesim,pure_creation_tesim, wf_status_tesim,
                                    retention_policy_tesim,restriction_note_tesim,last_access_tesim,
                                    number_of_downloads_isim',
                                     @results_per_page, solr_sort_fields.join(","),
                                     (@current_page - 1) * @results_per_page)
      end
    end


    if response.nil?
      @deposits = []
    else
      @deposits = response
    end

    # get the 'deposit status' fields via qa
    load_status_fields

    respond_to do |format|
      if params[:refresh]
        format.html { redirect_to deposits_path }
        format.json { render :index }
      else
        format.html { render :index }
        format.json { render :index }
      end
    end
  end

  # GET /deposits/1
  # GET /deposits/1.json
  def show
    if params[:deposit]
      # if the user uploaded local file(s), they will be sitting in @temp_upload_dir
      uploaded_files_dir = File.join(@temp_upload_dir, @dataset.id)
      if Dir.exists?(uploaded_files_dir)
        begin
          @aip = create_aip
          set_user_deposit(@dataset, params[:deposit][:readme])
          new_deposit(@dataset.id, @aip.id)
          add_metadata(@dataset.for_indexing[0])
          # handle readme (submission documentation)
          if params[:deposit][:readme] and !params[:deposit][:readme].empty?
            deposit_submission_documentation(params[:deposit][:readme])
          end
          # move uploaded files from temp upload dir to the deposit dir where Archivematica will be able to see them
          FileUtils.mv(Dir.glob(File.join(uploaded_files_dir, "*")), @dir_aip)
          FileUtils.remove_dir(uploaded_files_dir)
        # if there was problem uploading files, delete the new AIP and delete any files that did get uploaded
        rescue => e
          # delete from aips membership
          @dataset.aips.delete(@dataset.aips.last)
          # delete aip
          delete_aip
          delete_deposited_files(@dataset.id)
          # notify RDM team about failed upload
          RdMailer.notify_rdm_team_about_dataset(@dataset.id, "An error occurred during data deposit: " + e.message, "Error during deposit", current_user).deliver_later
          flash.now[:error] = 'Failed to deposit selected files: ' + e.message
        else
          # notify RDM team about successful deposit
          RdMailer.notify_rdm_team_about_dataset(@dataset.id, "A deposit has been successfully uploaded", "Data deposited", current_user).deliver_later
          flash.now[:notice] = 'The deposit was successful.'
          @dataset = nil
        end
      else
        flash.now[:error] = "You didn't deposit any data!"
      end
    end
    respond_to do |format|
      format.html { render :show }
      format.json { render :show, status: :created, location: @deposit }
    end
  end

  # POST /deposits/1/fileupload.json
  def fileupload
    if params[:deposit][:file] and not params[:deposit][:file].empty? and params[:id] and params[:size]
      begin
        path = params[:path] ? params[:path] : ""
        deposit_file_chunk_from_client(params[:deposit][:file][0], path, params[:id], params[:size])
        @files = params[:deposit][:file]
      rescue => e
        delete_deposited_files(params[:id])
        RdMailer.notify_rdm_team_about_dataset(params[:id], "An error occurred during local file upload: " + e.message, "Error during deposit", current_user).deliver_later
        raise
      end
    end
  end

  # GET /deposits/1/getgdrivefile.json
  def getgdrivefile
    @data = {}
    if params[:fileid] and params[:path] and params[:size] and params[:dataset_id] and params[:mime_type]
      begin
        deposit_file_from_google(params[:fileid], params[:path], params[:mime_type], params[:dataset_id], params[:size], params[:byte_from], params[:byte_to])
        @data = {"path" => params[:path], "filesize" => params[:size], "byte_from" => params[:byte_from], "byte_to" => params[:byte_to]}
      rescue => e
        delete_deposited_files(params[:dataset_id])
        RdMailer.notify_rdm_team_about_dataset(params[:id], "An error occurred during google drive file upload: " + e.message, "Error during deposit", current_user).deliver_later
        raise e
      end
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
        @dataset_id = params[:deposit][:id].to_s
        d = Dlibhydra::Dataset.find(@dataset_id)
        if params[:deposit][:status]
          d.wf_status = params[:deposit][:status]
        else
          d.wf_status = []
        end
        if params[:deposit][:retention_policy]
          d.retention_policy = [params[:deposit][:retention_policy]]
        end
        if params[:notes]
          d.restriction_note += [params[:notes]]
        end
        if params[:delete_note_at_index] and params[:delete_note_at_index].match(/^\d+$/)
          notes = d.restriction_note.to_a
          notes.delete_at(params[:delete_note_at_index].to_i)
          d.restriction_note = notes
        end
        d.save
        @deposit.status = d.wf_status.to_a
        @deposit.retention_policy = d.retention_policy.to_a[0]
        # the following ".to_a.to_s" is to make the value consistent with how it's returned from the solr query in the index 
        # method so that it can be treated the same way by the _notes.html.erb partial
        @deposit.notes = d.restriction_note.to_a.to_s

        # load status fields from QA for presenting in 'status' column of deposits table
        load_status_fields


        respond_to do |format|
          #format.html { render :show, notice: notice }
          format.js
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

  # Notes
  def notes
    respond_to do |format|
      #format.html { render :show, notice: notice }
      format.js {}
      #format.json { render :show, status: :created, location: @deposit }
    end
  end

  # Reingest
  def reingest
    message = reingest_aip('objects', params[:id])
    flash.now[:notice] = message
    respond_to do |format|
      format.html { redirect_to deposits_url, notice: message['message'] }
      format.json { head :no_content }
    end
  end

  def dipuuid
    message = update_dip(params[:deposit][:id],params[:deposit][:dipuuid])
    respond_to do |format|
      if !message.empty?
        format.html { redirect_to deposits_url, notice: message }
      else 
        format.html { redirect_to deposits_url }
      end
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_deposit
    @deposit = Deposit.new
    @dataset = Dlibhydra::Dataset.find(params[:id])
  end

  def set_globals
    # define the location where temporary file uploads will go
    @temp_upload_dir = File.join(ENV['TRANSFER_LOCATION'], "tmp") 
    # define the location where deposits should end up so Archivematica will find them
    @deposit_dir = File.join(ENV['TRANSFER_LOCATION'], "archivematica")
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def deposit_params
    params.permit(:deposit, :uuid, :file, :submission_doco,
                  :title, :refresh, :refresh_num, :refresh_from,
                  :pure_uuid, :readme, :access,
                  :embargo_end, :available, :dipuuid, :status, :release, :q, :aip_status, :dip_status, :doi,:retention_policy, :notes)
  end

  private

  # Given a Puree collection (an array of hashes), get each dataset
  # Create a new Hydra dataset, or update an existing one
  # Ignore data not published by the given publisher
  def get_datasets_from_collection(c, response, new_uuids=[])

    c.each do |puree_d|
      unless puree_d['publisher'].exclude? ENV['PUBLISHER']
        if response != nil and (new_uuids.include? puree_d['uuid'] or response.to_s.include? puree_d['uuid'])
          r = solr_query_short('pure_uuid_tesim:"' + puree_d['uuid'] + '"', 'id', 1)
          local_d = find_dataset(r['docs'][0]['id'])
        else
          new_uuids << puree_d['uuid']
          local_d = new_dataset
        end

        set_metadata(local_d, puree_d)
      end
    end
    new_uuids
  end

  # if the current user isn't logged in and isn't an administrator, tell them they need to an admin to do what they were trying to do
  def verify_is_admin
    unless current_user && current_user.admin?
      render :html => "<h1>Unauthorised</h1><p>You are not authorised to view this page</p>".html_safe, :status => :unauthorized, :layout => 'blacklight'
    end 
  end

  # get the form fields/values necessary to populate the 'status' column in the main dashboard - using questioning authority (qa)
  # note: the files that define the 'authorities' are in config/authorities
  def load_status_fields
    @deposit_status_general = Qa::Authorities::Local::FileBasedAuthority.new('deposit_status_general').all
    @deposit_status_data = Qa::Authorities::Local::FileBasedAuthority.new('deposit_status_data').all
    @deposit_status_access = Qa::Authorities::Local::FileBasedAuthority.new('deposit_status_access').all
    @deposit_status_retention = Qa::Authorities::Local::FileBasedAuthority.new('deposit_status_retention').all
  end 

end
