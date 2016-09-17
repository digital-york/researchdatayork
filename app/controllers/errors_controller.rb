class ErrorsController < ApplicationController

  # Mostly borrowed from https://samurails.com/jutsu/rails-jutsu/jutsu-12-custom-error-pages-in-rails-4/
  
  #Response
  respond_to :html, :xml, :json

  #Details
  before_action :status

  #######################

  # handle all unhandled exceptions
  def show
    # if the exception was caused by fedora, such as unable to connect to fedora 
    # then pretty much nothing in the application will work, not even loading assets, so it 
    # needs to be handled specially
    fedora_dev_uri = nil
    fedora_prod_uri = nil
    if ENV['FEDORA_DEV'] 
      fedora_dev_uri = URI.parse(ENV['FEDORA_DEV']) rescue nil
    end
    if ENV['FEDORA_PROD']
      fedora_prod_uri = URI.parse(ENV['FEDORA_PROD']) rescue nil
    end
    # if the error message mentions the fedora server url/port
    if (fedora_dev_uri.nil? and fedora_prod_uri.nil?) or
       (fedora_dev_uri.try(:host).nil? and fedora_prod_uri.try(:host).nil?) or
       (!fedora_dev_uri.nil? and details[:message].include? fedora_dev_uri.host and details[:message].include? fedora_dev_uri.port.to_s) or
       (!fedora_prod_uri.nil? and details[:message].include? fedora_prod_uri.host and details[:message].include? fedora_prod_uri.port.to_s)
      # it's a fedora error - handle it specially 
      render(:fedora, :status => @status, :layout => false)
    else
      # it's a non-fedora error - handle it normally
      render(:status => @status)
    end
  end

  #######################

  protected

  #Info
  def status
     @exception  = env['action_dispatch.exception']
     @status     = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code
     @response   = ActionDispatch::ExceptionWrapper.rescue_responses[@exception.class.name]
  end

  #Format
  def details
    @details ||= {}.tap do |h|
      I18n.with_options scope: [:exception, :show, @response], exception_name: @exception.class.name, exception_message: @exception.message do |i18n|
           h[:name]    = i18n.t "#{@exception.class.name.underscore}.title", default: i18n.t(:title, default: @exception.class.name)
           h[:message] = i18n.t "#{@exception.class.name.underscore}.description", default: i18n.t(:description, default: @exception.message)
      end
    end
  end
  helper_method :details

  #######################

  private

  #Layout
  def layout_status
      @status.to_s == "404" ? "application" : "error"
  end

end
