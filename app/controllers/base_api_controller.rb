class BaseApiController < ApplicationController
  before_filter :parse_request, :verify_key!

  def validate_json(condition)
    render nothing: true, status: :bad_request unless condition
  end

  # not using
  def update_values(ivar, attributes)
    # assign attributes won't work
    attributes.map.each do |k, _v|
      # check key is valid for this object
      check_existence(ivar, k)
      # set
    end
  end

  def check_existence(ivar, key)
    # hmm
  end

  private

  def verify_key!
    if !@json['package']['api-key']
      render nothing: true, status: :unauthorized
    else
      unless @json['package']['api-key'] == ENV['ARCHIVEMATICA_API_KEY']
        render nothing: true, status: :unauthorized
      end
    end
  end

  def parse_request
    @json = JSON.parse(request.body.read)
  end
end
