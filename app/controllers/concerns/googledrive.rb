module Googledrive
  extend ActiveSupport::Concern

  require 'google/apis/drive_v3'
  require 'fileutils'
  require 'httplog'

  # are we connected/authenticated to the Google API?
  def connected_to_google_api?
    # if we have a refresh token stored then we're connected
    session.key?(:refresh_token)
  end

  # create a new oauth2client with all the attributes that remain constant and return it
  def oauth2client
    # (mostly taken from http://readysteadycode.com/howto-access-the-google-calendar-api-with-ruby)
    client = Signet::OAuth2::Client.new(client_id: ENV.fetch('GOOGLE_API_CLIENT_ID'),
                                        client_secret: ENV.fetch('GOOGLE_API_CLIENT_SECRET'),
                                        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
                                        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
                                        scope: Google::Apis::DriveV3::AUTH_DRIVE_READONLY,
                                        redirect_uri: oauth2callback_googledrive_index_url)
    client
  end

  # create a Google Drive API object, authenticate and return it
  def initialise_api
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = 'Research Data York Google Drive Browser'
    client = oauth2client
    client.update!(refresh_token: session[:refresh_token])
    client.fetch_access_token!
    service.authorization = client
    service
  end

  # given a google drive folder id, return the files in that folder
  def list_files_in_folder(folder)
    # Initialise the API
    service = initialise_api
    files = service.list_files(q: "'#{folder}' in parents and trashed=false", order_by: 'folder,modifiedTime desc,name',
                               fields: 'files(id, name, parents, iconLink, mimeType, size)')
    files
  end

  # return an array of google's export mime types and file extensions for google documents
  # these values are documented at https://developers.google.com/drive/v3/web/manage-downloads
  # and at https://developers.google.com/drive/v3/web/mime-types
  def google_docs_mimetypes
    types = {}
    types['application/vnd.google-apps.document'] = { 'export_mimetype' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                                      'export_extension' => '.docx' }
    types['application/vnd.google-apps.spreadsheet'] = { 'export_mimetype' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                                         'export_extension' => '.xlsx' }
    types['application/vnd.google-apps.drawing'] = { 'export_mimetype' => 'image/jpeg',
                                                     'export_extension' => '.jpg' }
    types['application/vnd.google-apps.presentation'] = { 'export_mimetype' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                                                          'export_extension' => '.pptx' }
    types['application/vnd.google-apps.script'] = { 'export_mimetype' => 'application/vnd.google-apps.script+json',
                                                    'export_extension' => '.json' }
    types
  end

  # given an initialised api service and a google drive file id, download the file and return it
  def get_file_from_google(service, fileid, mime_type, byte_from = nil, byte_to = nil)
    file_contents = StringIO.new
    # if the mime type for this file is a google document
    if google_docs_mimetypes.key?(mime_type)
      # find a suitable export mime type according to table at https://developers.google.com/drive/v3/web/manage-downloads
      export_mime_type = google_docs_mimetypes[mime_type]['export_mimetype']
      # export the file from google drive
      file = service.export_file(fileid, export_mime_type, download_dest: file_contents)
    # otherwise it's a "normal" file - just download it
    else
      # specify which bytes we want to download if byte range given
      options = (byte_from && byte_to) ? {header: {"Range" => "bytes=" + byte_from.to_s + "-" + byte_to.to_s}} : {}
      file = service.get_file(fileid, download_dest: file_contents, options: options)
    end
    file_contents
  end
end
