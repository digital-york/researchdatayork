class GoogledriveController < ApplicationController

  include Googledrive

  def index
   # default folder to search is the "root" folder
    @parent_folder = "root"
    # if given a folder param, use that
    if params[:folder]
      @parent_folder = params[:folder]
    end
    @response = list_files_in_folder(@parent_folder)
    respond_to do |format|
      format.json { render :index }
    end
  end

end
