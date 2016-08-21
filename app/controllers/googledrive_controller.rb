class GoogledriveController < ApplicationController

  require 'google/apis/drive_v3'
  require 'googleauth'
  require 'googleauth/stores/file_token_store'

  require 'fileutils'
    
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Drive API Ruby Quickstart'
  CLIENT_SECRETS_PATH = 'client_secret.json'
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials', "drive-ruby-quickstart.yaml")
  SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY

  def authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization"
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def index
    # Initialize the API
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
    # List the 10 most recently modified files.
    #@response = service.list_files(page_size: 10, fields: 'nextPageToken, files(id, name)')
    # default folder to search is the "root" folder
    @parent_folder = "root"
    # if given a folder param, use that
    if params[:folder]
      @parent_folder = params[:folder]
      @response = service.list_files(q: "'#{@parent_folder}' in parents and trashed=false", order_by: "folder,modifiedTime desc,name", 
                                   fields: "files(id, name, parents, iconLink, mimeType)")
    end
    #puts 'Files:'
    #puts 'No files found' if @response.files.empty?
    #@response.files.each do |file|
    #  puts "#{file.name} (#{file.id})"
    #end
    respond_to do |format|
      format.html { render :index, :layout => false }
      format.json { render :index }
    end
  end

end
