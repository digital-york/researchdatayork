module Googledrive
  extend ActiveSupport::Concern

  require 'google/apis/drive_v3'
#  require 'googleauth'
#  require 'googleauth/stores/file_token_store'
#  require 'google/api_client'
  
  require 'fileutils'
    
#  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
#  APPLICATION_NAME = 'Research Data York Google Drive Browser'
#  CLIENT_SECRETS_PATH = 'client_secret.json'
#  CREDENTIALS_PATH = File.join(Dir.home, '.credentials', "drive-ruby-quickstart.yaml")
  #SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY
  #SCOPE = 'https://www.googleapis.com/auth/drive'
#  SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_READONLY

#  def authorize
#    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))
#
#    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
#    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
#    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
#    user_id = 'default'
#    credentials = authorizer.get_credentials(user_id)
#    if credentials.nil?
#      url = authorizer.get_authorization_url(base_url: OOB_URI)
#      puts "Open the following URL in the browser and enter the resulting code after authorization"
#      puts url
#      code = gets
#      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
#    end
#    credentials
#  end

  # define a simple class for Google API access tokens, as described at
  # https://github.com/google/google-api-ruby-client/issues/296
  class AccessToken
    attr_reader :token
    def initialize(token)
      @token = token
    end

    def apply!(headers)
      headers['Authorization'] = "Bearer #{@token}"
    end
  end

  # connect the the Google API and begin the process of authenticating
  # (mostly taken from http://readysteadycode.com/howto-access-the-google-calendar-api-with-ruby)
  def connect_to_google_api
    client = Signet::OAuth2::Client.new({
      client_id: ENV.fetch('GOOGLE_API_CLIENT_ID'),
      client_secret: ENV.fetch('GOOGLE_API_CLIENT_SECRET'),
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: Google::Apis::DriveV3::AUTH_DRIVE_READONLY,
      redirect_uri: oauth2callback_googledrive_index_url
    })
    redirect_to client.authorization_uri.to_s
  end

  # handle the callback from Google (it will respond to the above call) and grab the authorisation code
  def handle_google_callback
    client = Signet::OAuth2::Client.new({
      client_id: ENV.fetch('GOOGLE_API_CLIENT_ID'),
      client_secret: ENV.fetch('GOOGLE_API_CLIENT_SECRET'),
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      redirect_uri: oauth2callback_googledrive_index_url,
      #code: params[:code]
    })
    response = client.fetch_access_token!
    session[:access_token] = response['access_token']
    #redirect_to googledrive_index_url
  end 

  def initialise_api
    handle_google_callback
    access_token = AccessToken.new session[:access_token]
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = "Research Data York Google Drive Browser"
    #service.authorization = authorize
    #service.authorization = Signet::OAuth2::Client.new(access_token: session[:access_token])
    service.authorization = access_token
    service
  end 

  # given a google drive folder id, return the files in that folder
  def list_files_in_folder (folder)
    # Initialise the API
    service = initialise_api
    #service = drive
    files = service.list_files(q: "'#{folder}' in parents and trashed=false", order_by: "folder,modifiedTime desc,name", 
                                   fields: "files(id, name, parents, iconLink, mimeType)")
#    files = service.execute(api_method: "list_files", parameters: {q: "'#{folder}' in parents and trashed=false", order_by: "folder,modifiedTime desc,name", 
#                                   fields: "files(id, name, parents, iconLink, mimeType)"})
    files
  end
  
  # return an array of google's export mime types and file extensions for google documents
  # these values are documented at https://developers.google.com/drive/v3/web/manage-downloads
  # and at https://developers.google.com/drive/v3/web/mime-types
  def google_docs_mimetypes
    types = Hash.new
    types["application/vnd.google-apps.document"] = {"export_mimetype" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                                     "export_extension" => ".docx"}
    types["application/vnd.google-apps.spreadsheet"] = {"export_mimetype" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                                                     "export_extension" => ".xlsx"}
    types["application/vnd.google-apps.drawing"] = {"export_mimetype" => "image/jpeg",
                                                     "export_extension" => ".jpg"}
    types["application/vnd.google-apps.presentation"] = {"export_mimetype" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                                                     "export_extension" => ".pptx"}
    types["application/vnd.google-apps.script"] = {"export_mimetype" => "application/vnd.google-apps.script+json",
                                                     "export_extension" => ".json"}
    types
  end
         

  # given an initialised api service and a google drive file id, download the file and return it
  def get_file_from_google (service, fileid, mime_type)
    file_contents = StringIO.new
    # if the mime type for this file is a google document
    if google_docs_mimetypes.has_key?(mime_type)
      # find a suitable export mime type according to table at https://developers.google.com/drive/v3/web/manage-downloads
      export_mime_type = google_docs_mimetypes[mime_type]["export_mimetype"]
      # export the file from google drive
      file = service.export_file(fileid, export_mime_type, download_dest: file_contents)
    # otherwise it's a "normal" file - just download it
    else
      file = service.get_file(fileid, download_dest: file_contents)
    end
    file_contents
  end

#  # Authorisation code (copied from BrowseEverything: https://github.com/projecthydra/browse-everything/blob/master/lib/browse_everything/driver/google_drive.rb)
#  def auth_link
#    oauth_client.authorization.authorization_uri.to_s
#  end

#  def authorized?
#    @token.present?
#  end

#  def connect(params, data)
#    oauth_client.authorization.code = params[:code]
#    @token = oauth_client.authorization.fetch_access_token!
#  end

#  def drive
#    oauth_client.discovered_api('drive', 'v2')
#  end

#  private

  #As per issue http://stackoverflow.com/questions/12572723/rails-google-client-api-unable-to-exchange-a-refresh-token-for-access-token

  #patch start
#  def token_expired?(token)
#    client=@client
#    result = client.execute( api_method: drive.files.list, parameters: {} )
#    (result.status != 200)
#  end

#  def exchange_refresh_token( refresh_token )
#    client=oauth_client
#    client.authorization.grant_type = 'refresh_token'
#    client.authorization.refresh_token = refresh_token
#    client.authorization.fetch_access_token!
#    client.authorization
#    client
#  end
  #patch end

#  def oauth_client
#    if @client.nil?
#      @client = Google::APIClient.new
#      @client.authorization.client_id = ENV["GOOGLE_API_CLIENT_ID"]
#      @client.authorization.client_secret = ENV["GOOGLE_API_CLIENT_SECRET"]
#      @client.authorization.scope = "https://www.googleapis.com/auth/drive"
#      @client.authorization.redirect_uri = url_for(:action => :oauth2callback)
#      @client.authorization.update_token!(@token) if @token.present?
      #Patch start
#      @client = exchange_refresh_token(@token["refresh_token"]) if @token.present? && token_expired?(@token)
      #Patch end
#   end
    #todo error checking here
#    @client
#  end


end
