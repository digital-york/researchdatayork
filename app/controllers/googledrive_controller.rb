class GoogledriveController < ApplicationController

  include Googledrive

  def index
    if session[:access_token]
      # default folder to search is the "root" folder
      @parent_folder = "root"
      # if given a folder param, use that
      if params[:folder]
        @parent_folder = params[:folder]
      end
      @response = list_files_in_folder(@parent_folder)
    else
      connect_to_google_api
    end
    respond_to do |format|
      format.json { render :index }
    end
  end

  # respond to Google's oauth2 request
  def oauth2callback
    puts "hello world!"
    client = Signet::OAuth2::Client.new({
      client_id: ENV.fetch('GOOGLE_API_CLIENT_ID'),
      client_secret: ENV.fetch('GOOGLE_API_CLIENT_SECRET'),
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      redirect_uri: url_for(:action => :oauth2callback),
      code: params[:code]
    })

    response = client.fetch_access_token!

    session[:access_token] = response['access_token']

    redirect_to url_for(:action => :index)
  end

end
