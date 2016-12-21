class ApiDipsController < BaseApiController
  before_action :find_dip, only: [:update]
  # avoid 'Can't verify CSRF token authenticity'
  # TODO look at whether using devise might be better?
  protect_from_forgery with: :null_session,
                       if: proc { |c| c.request.format =~ %r{application/json} }
  include Dlibhydra
  include CreateDip

  # https://www.airpair.com/ruby-on-rails/posts/building-a-restful-api-in-a-rails-application

  before_filter only: [:update] do |c|
    meth = c.method(:validate_json)
    meth.call @json.key?('package')
  end

  # this now replaces update_dip
  def update
    dip_uuid(@json['package']['dip_uuid']) unless @json['package']['dip_uuid'].nil?
    dip_current_path(@json['package']['current_path']) unless @json['package']['current_path'].nil?
    dip_resource_uri(@json['package']['resource_uri']) unless @json['package']['resource_uri'].nil?
    dip_current_location(@json['package']['current_location']) unless @json['package']['current_location'].nil?
    dip_size(@json['package']['size']) unless @json['package']['current_location'].nil?

    # we do get status, change this
    @dip.dip_status = 'UPLOADED'

    if @dip.save
      ingest_dip(@dip.dip_current_path,@dip.id)
      render json:  @dip.to_json, status: :ok
    else
      render nothing: true, status: :bad_request
    end

  end

  def waiting
    if waiting_for_dips.empty?
      render nothing: true, status: :no_content
    else
      render json: waiting_for_dips.to_json, status: :ok
    end

  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def find_dip
    @dip = Dlibhydra::Package.find(params[:id])
    render nothing: true, status: :not_found unless @dip.present?
  end
end
