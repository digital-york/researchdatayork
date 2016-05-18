class DepositsController < ApplicationController
  before_action :set_deposit, only: [:show, :edit, :update, :destroy]
  include Dlibhydra
  include Puree

  # GET /deposits
  # GET /deposits.json
  def index
    c = Puree::Collection.new(resource_type: :dataset)

    # Get minimal datasets, optionally specifying a quantity (default is 20)
    c.get endpoint: ENV['PURE_ENDPOINT'],
          username: ENV['PURE_USERNAME'],
          password: ENV['PURE_PASSWORD'],
          qty:      10

    # not deposits, datasets
    @deposits = c.uuid
        #Dlibhydra::Dataset.all

  end

  # GET /deposits/1
  # GET /deposits/1.json
  def show
  end

  # GET /deposits/new
  def new
    # here should have an id attribute
    # should be an existing pure uuid
    @deposit = Deposit.new
        #Dlibhydra::Aip.new
    @dataset = Dlibhydra::Dataset.new
  end

  # GET /deposits/1/edit
  def edit
  end

  # POST /deposits
  # POST /deposits.json
  def create
    # @deposit = deposit.new(deposit_params)
    @dataset.preflabel = deposit_params[:uuid]
    puts deposit_params[:file]
    dir = ENV['TRANSFER_LOCATION'] + '/' + deposit_params[:uuid] + '/'
    FileUtils.mkdir(dir)
    FileUtils.mkdir(dir + 'submissionDocumentation')
    FileUtils.chmod 0644,deposit_params[:file].tempfile
    FileUtils.mv(deposit_params[:file].tempfile,dir + deposit_params[:file].original_filename)

    # don't save the deposit
    respond_to do |format|
      if @dataset.save
        format.html { redirect_to @deposit, notice: 'deposit was successfully created.' }
        format.json { render :show, status: :created, location: @deposit }
      else
        format.html { render :new }
        format.json { render json: @deposit.errors, status: :unprocessable_entity }
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
      params.require(:deposit).permit(:uuid,:file,:title,:people)
    end
end
