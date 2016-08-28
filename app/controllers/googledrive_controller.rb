class GoogledriveController < ApplicationController

  include Googledrive

  # connect to the Google API and begin the process of autheticating
  def connect
    # if we're already connected to the API
    if session[:access_token]
      # just redirect straight to the finish
      redirect_to finish_googledrive_index_url
    else
    # (mostly taken from http://readysteadycode.com/howto-access-the-google-calendar-api-with-ruby)
      client = Signet::OAuth2::Client.new({
        client_id: ENV.fetch('GOOGLE_API_CLIENT_ID'),
        client_secret: ENV.fetch('GOOGLE_API_CLIENT_SECRET'),
        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        scope: Google::Apis::DriveV3::AUTH_DRIVE_READONLY,
        redirect_uri: oauth2callback_googledrive_index_url
      })
      redirect_to client.authorization_uri.to_s
    end
  end

  # handle the callback from Google (it will respond to the above call) and grab the authorisation code
  def oauth2callback
    client = Signet::OAuth2::Client.new({
      client_id: ENV.fetch('GOOGLE_API_CLIENT_ID'),
      client_secret: ENV.fetch('GOOGLE_API_CLIENT_SECRET'),
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      redirect_uri: oauth2callback_googledrive_index_url,
      code: params[:code]
    })
    response = client.fetch_access_token!
    session[:access_token] = response['access_token']
    redirect_to finish_googledrive_index_url
  end 

  # finish off the connection process
  def finish
    respond_to do |format|
      format.html { render :finish }
    end
  end

  # get a list of the user's google drive files in a specified folder (default to "root") and respond with json
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
