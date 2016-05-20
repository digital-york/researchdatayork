class DepositsController < ApplicationController
  before_action :set_deposit, only: [:show, :edit, :update, :destroy]
  include Dlibhydra
  include Puree

  #20ee85c3-f53c-4ab6-8e50-270b0ddd3686
  # there is a problem with project
  #e3f87d05-ab3c-49ef-a69d-0a9805b77d2f - live object with project

  # GET /deposits
  # GET /deposits.json
  def index

    # For users who aren't logged in, ask for their ID

    # This is a basic ActiveRecord object. It is never saved.
    @deposit = Deposit.new

    # Get all dataset records from Solr
    solr = RSolr.connect :url => ENV['SOLR_DEV']
    # Get number of results to return
    resp = solr.get 'select', :params => {
        :q => 'has_model_ssim:"Dlibhydra::Dataset"',
        :rows => 0
    }

    unless resp['response']['numFound'] == 0
      response = solr.get 'select', :params => {
          :q => 'has_model_ssim:"Dlibhydra::Dataset"',
          :fl => 'pure_uuid_tesim',
          :rows => resp['response']['numFound']
      }
    end

    if params[:refresh] == 'true'
      c = Puree::Collection.new(resource_type: :dataset)
      quantity = 5
      unless params[:refresh_num].nil?
        quantity = params[:refresh_num]
      end

      # Get minimal datasets, optionally specifying a quantity (default is 20)
      c.get endpoint: ENV['PURE_ENDPOINT'],
            username: ENV['PURE_USERNAME'],
            password: ENV['PURE_PASSWORD'],
            qty: quantity

      c.uuid.each do |uuid|
        local_d = Dlibhydra::Dataset.new
        d = Puree::Dataset.new
        d.get endpoint: ENV['PURE_ENDPOINT'],
              username: ENV['PURE_USERNAME'],
              password: ENV['PURE_PASSWORD'],
              uuid: uuid

        # Only include UoY datasets
        # Update those for which a record already exists
        unless d.publisher.exclude? 'University of York'
          if response.to_s.include? uuid
            r = solr.get 'select', :params => {
                :q => 'pure_uuid_tesim:"' + uuid + '"',
                :fl => 'id',
                :rows => 1
            }
            local_d = Dlibhydra::Dataset.find(r['response']['docs'][0]['id'])
          end
          local_d.pure_uuid = uuid
          local_d.preflabel = d.title

          if d.access == ''
            local_d.access_rights = 'not set'
          else
            local_d.access_rights = d.access
          end
          local_d.date_available = "#{d.available['year']}"
          unless d.available[:month] == ''
            local_d.date_available = "#{d.available['year']}/#{d.available['month']}}"
          end
          unless d.available[:year] == ''
            local_d.date_available = "#{d.available['year']}/#{d.available['month']}/#{d.available['day']}"
          end
          local_d.index_dump = d.metadata.to_s
          local_d.save
        end

      end

    end

    # check if we have it in solr, if not create a dataset
    resp = solr.get 'select', :params => {
        :q => 'has_model_ssim:"Dlibhydra::Dataset"',
        :rows => 0
    }

    unless resp['response']['numFound'] == 0
      response = solr.get 'select', :params => {
          :q => 'has_model_ssim:"Dlibhydra::Dataset"',
          :fl => 'id,pure_uuid_tesim,preflabel_tesim,date_available_tesim,access_rights_tesim',
          :rows => resp['response']['numFound']
      }
    end
    # Change this to provide only the bit of the response we need to look through!
    if response.nil?
      @deposits = []
    else
      @deposits = response['response']
    end
  end

  # GET /deposits/1
  # GET /deposits/1.json
  def show

    @notice = ''

    if params[:deposit]
      if params[:deposit][:file]
        @aip = Dlibhydra::Aip.new
        @aip.preflabel = 'Dataset AIP'
        @aip.readme = params[:deposit][:readme]
        @aip.save
        @dataset.aip << @aip
        @dataset.save

        @notice = 'The deposit was successful.'

        dir_pure = ENV['TRANSFER_LOCATION'] + '/' + @dataset.pure_uuid
        dir = dir_pure + '/' + params[:id] + '/'

        # write metadata.json

        # TODO check if first bit exists
        FileUtils.mkdir(dir_pure)
        FileUtils.mkdir(dir)
        FileUtils.mkdir(dir + 'submissionDocumentation')
        FileUtils.chmod 0644, params[:deposit][:file].tempfile
        FileUtils.mv(params[:deposit][:file].tempfile, dir + params[:deposit][:file].original_filename)
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
    # Use this for a new dataset
  end

  # GET /deposits/1/edit
  def edit
    # Use this for editing datasets
  end

  # POST /deposits
  # POST /deposits.json
  def create
    # Move this into the if statement

    @dataset = Dlibhydra::Dataset.new
    if params[:deposit][:pure_uuid]

      uuid = params[:deposit][:pure_uuid]
      query = 'pure_uuid_tesim:"' + uuid + '""'
      notice = 'PURE data was successfully added.'

      solr = RSolr.connect :url => ENV['SOLR_DEV']
      response = solr.get 'select', :params => {
          :q => query,
          :rows => 1,
          :fl => 'id,pure_uuid_tesim'
      }
      if response['response']['numFound'] > 0
        notice = 'Dataset object already exists for this PURE UUID. Metadata updated.'
        r = solr.get 'select', :params => {
            :q => 'pure_uuid_tesim:"' + uuid + '"',
            :fl => 'id',
            :rows => 1
        }
        @dataset = Dlibhydra::Dataset.find(r['response']['docs'][0]['id'])
      end

      d = Puree::Dataset.new
      d.get endpoint: ENV['PURE_ENDPOINT'],
            username: ENV['PURE_USERNAME'],
            password: ENV['PURE_PASSWORD'],
            uuid: uuid
      @dataset.pure_uuid = uuid
      @dataset.preflabel = d.title
      puts d.metadata
      if d.access == ''
        @dataset.access_rights = 'not set'
      else
        @dataset.access_rights = d.access
      end

      @dataset.date_available = "#{d.available['year']}"
      unless d.available[:month] == ''
        @dataset.date_available = "#{d.available['year']}/#{d.available['month']}}"
      end
      unless d.available[:year] == ''
        @dataset.date_available = "#{d.available['year']}/#{d.available['month']}/#{d.available['day']}"
      end
      @dataset.index_dump = d.metadata.to_s
      @dataset.save

      respond_to do |format|
        format.html { redirect_to deposits_path, notice: notice }
        format.json { render :index, status: :created, location: @dataset }
      end
    else
      # Create new dataset from scratch
      notice = 'The deposit was successful.'

      respond_to do |format|
        if @dataset.save
          format.html { render :show, notice: notice }
          format.json { render :show, status: :created, location: @deposit }
        else
          format.html { render :new }
          format.json { render json: @deposit.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /deposits/1
  # PATCH/PUT /deposits/1.json
  def update
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
    @deposit.destroy
    respond_to do |format|
      format.html { redirect_to deposits_url, notice: 'deposit was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # Search
  def search

  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_deposit
    @deposit = Deposit.new
    @dataset = Dlibhydra::Dataset.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  # TODO add contact email/name
  def deposit_params
    params.permit(:deposit, :uuid, :file, :submission_doco,
                  :title, :refresh, :refresh_num,
                  :pure_uuid, :readme, :access,
                  :embargo_end, :available)
  end
end
