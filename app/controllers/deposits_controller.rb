class DepositsController < ApplicationController
  before_action :set_deposit, only: [:show, :edit, :update, :destroy]
  include Dlibhydra
  include Puree

  #20ee85c3-f53c-4ab6-8e50-270b0ddd3686

  # GET /deposits
  # GET /deposits.json
  def index

    # This is a basic ActiveRecord object. It is never saved.
    @deposit = Deposit.new

    # Get all dataset records from Solr
    solr = RSolr.connect :url => ENV['SOLR_DEV']
    # add get number step here?
    response = solr.get 'select', :params => {
        :q => 'has_model_ssim:"Dlibhydra::Dataset"',
        :fl => 'pure_uuid_tesim',
        :rows => 500
    }

    if params[:refresh] == 'true'
      c = Puree::Collection.new(resource_type: :dataset)
      quantity = 100
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
        unless response.to_s.include? uuid
          local_d.pure_uuid = uuid
          local_d.preflabel = d.title[0]
          local_d.save
        end

      end
      @deposits = [response.to_s]
      @deposits = c.uuid

    end

    # check if we have it in solr, if not create a dataset
    response = solr.get 'select', :params => {
        :q => 'has_model_ssim:"Dlibhydra::Dataset"',
        :fl => 'id,pure_uuid_tesim,preflabel_tesim',
        :rows => 100
    }
    # Change this to provide only the bit of the response we need to look through!
    @deposits = [response.to_s]

  end

  # GET /deposits/1
  # GET /deposits/1.json
  def show
  end

  # GET /deposits/new
  def new
    # This is a basic ActiveRecord object. It is never saved.
    @deposit = Deposit.new
  end

  # GET /deposits/1/edit
  def edit
  end

  # POST /deposits
  # POST /deposits.json
  def create
    # Move this into the if statement

    @dataset = Dlibhydra::Dataset.new
    if params[:deposit][:pure_uuid]

      uuid = params[:deposit][:pure_uuid]
      query = 'pure_uuid_tesim:"' + uuid + '"'
      notice = 'PURE data already added'

      solr = RSolr.connect :url => ENV['SOLR_DEV']
      response = solr.get 'select', :params => {
          :q => query,
          :rows => 0
      }

      d = Puree::Dataset.new
      d.get endpoint: ENV['PURE_ENDPOINT'],
            username: ENV['PURE_USERNAME'],
            password: ENV['PURE_PASSWORD'],
            uuid: uuid
      unless response.to_s.include? uuid
        @dataset.pure_uuid = uuid
        @dataset.preflabel = d.title[0]
        @dataset.save
        notice = 'PURE data was successfully added.'
      end
      respond_to do |format|
        format.html { redirect_to deposits_path, notice: notice }
        format.json { render :index, status: :created, location: @dataset }
      end
    else
      # For the other form we should have an id for the dataset, look this up and create new Aip
      # If we don't have an id, sent back an error or could we hide the form?
      notice = 'The deposit was successful.'

      #Dlibhydra::Aip.new
      @dataset.preflabel = deposit_params[:uuid]
      dir = ENV['TRANSFER_LOCATION'] + '/' + deposit_params[:uuid] + '/'
      FileUtils.mkdir(dir)
      FileUtils.mkdir(dir + 'submissionDocumentation')
      FileUtils.chmod 0644, deposit_params[:file].tempfile
      FileUtils.mv(deposit_params[:file].tempfile, dir + deposit_params[:file].original_filename)
      respond_to do |format|
        if @dataset.save
          format.html { render :show, notice: 'deposit was successfully made.' }
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

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_deposit
    @deposit = deposit.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def deposit_params
    params.require(:deposit).permit(:uuid, :file, :title, :people, :refresh, :refresh_num, :pure_uuid)
  end
end
