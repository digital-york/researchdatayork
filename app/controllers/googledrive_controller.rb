class GoogledriveController < ApplicationController

  include Googledrive

  # get a list of the user's google drive files in a specified folder (default to "root") and respond with json
  def index
    # if we're connected and autheticated to the Google API, go ahead and make the request
    if session[:access_token]
      # default folder to search is the "root" folder
      @parent_folder = "root"
      # if given a folder param, use that
      if params[:folder]
        @parent_folder = params[:folder]
      # or if the folder has been stored in the session, use that
      elsif session[:folder]
        @parent_folder = session[:folder]
      end
      @response = list_files_in_folder(@parent_folder)
    # otherwise, we need to connect and authenticate to the Google API
    else
      # if given a folder param, store it in the session so that we remember it after the authentication process has completed
      if params[:folder]
        session[:folder] = params[:folder]
      end
      # connect/authenticate to Google API
      return connect_to_google_api
    end
    respond_to do |format|
      format.json { render :index }
    end
  end

  # respond to Google's oauth2 request
  def oauth2callback
    handle_google_callback
  end

end
