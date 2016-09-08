require 'rails_helper'

RSpec.describe 'datasets/edit', type: :view do
  before(:each) do
    @dataset = assign(:dataset, Dataset.create!)
  end

  it 'renders the edit dataset form' do
    render

    assert_select 'form[action=?][method=?]', dataset_path(@dataset), 'post' do
    end
  end
end
