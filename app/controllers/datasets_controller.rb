class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show]
  include Dlibhydra
  include CreateDataset

  # GET /datasets
  # GET /datasets.json
  def index

  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    @dataset = find_dataset(params[:id])
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dataset

    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dataset_params
      params.fetch(:dataset, {})
    end
end
