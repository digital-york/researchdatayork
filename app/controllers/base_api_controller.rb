class BaseApiController < ApplicationController
  before_filter :parse_request, :verify_key!

  def validate_json(condition)
    unless condition
      render nothing: true, status: :bad_request
    end
  end

  # not using
  def update_values(ivar, attributes)
    # assign attributes won't work
    attributes.map.each do | k,v|
      # check key is valid for this object
      check_existence(ivar,k)
      # set
    end

  end

  def check_existence(ivar, key)
    # hmm
  end

  private
  def verify_key!
    if !@json['aip']['api-key']
      render nothing: true, status: :unauthorized
    else
      unless @json['aip']['api-key'] == ENV['ARCHIVEMATICA_API_KEY']
        render nothing: true, status: :unauthorized
      end
    end
  end

  def parse_request
    @json = JSON.parse(request.body.read)
  end
end