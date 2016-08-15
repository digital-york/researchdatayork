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
  def show
    @notice = ''
    @dataset = find_dataset(params[:id])
    @dip_files = dip_directory_structure(@dataset)
    if params[:request]
      if params[:request][:email].include? '@'
        @notice = "Thank you. We will send you an email when the data is available."
        create_dip(@dataset)
        set_requestor_email(params[:request][:email])
        save_dip

      else
        @notice = 'Please provide a full email address.'
      end
    end
    respond_to do |format|
      format.html { render :show, notice: @notice }
      format.json { render :show, status: :created, location: @deposit }
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
end
