require 'rails_helper'

RSpec.describe "uploads/index", type: :view do
  before(:each) do
    assign(:uploads, [
      Upload.create!(
        :uuid => "Uuid"
      ),
      Upload.create!(
        :uuid => "Uuid"
      )
    ])
  end

  it "renders a list of uploads" do
    render
    assert_select "tr>td", :text => "Uuid".to_s, :count => 2
  end
end
