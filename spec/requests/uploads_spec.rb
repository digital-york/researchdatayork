require 'rails_helper'

RSpec.describe 'deposits', type: :request do
  describe 'GET /deposits' do
    it 'works! (now write some real specs)' do
      get deposits_path
      expect(response).to have_http_status(200)
    end
  end
end
