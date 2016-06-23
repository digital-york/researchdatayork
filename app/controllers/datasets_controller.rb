class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show]
  include Dlibhydra
  include CreateDataset
  include CreateDip

  # GET /datasets
  # GET /datasets.json
  def index

  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    @dataset = find_dataset(params[:id])
    if params[:request]
      create_dip
      set_first_requestor(params[:request][:email])
      set_dip_preflabel('DIP for ' + @dataset.pure_uuid)
      save_dip
      set_dip_member_of(@dataset)
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
