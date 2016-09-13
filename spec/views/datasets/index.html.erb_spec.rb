require 'rails_helper'

RSpec.describe 'datasets/index', type: :view do
  before(:each) do
    assign(:datasets, [
             Dataset.create!,
             Dataset.create!
           ])
  end

  it 'renders a list of datasets' do
    render
  end
end
