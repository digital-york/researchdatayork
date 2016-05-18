require 'rails_helper'

RSpec.describe "deposits/index", type: :view do
  before(:each) do
    assign(:deposits, [
      deposit.create!(
        :uuid => "Uuid"
      ),
      deposit.create!(
        :uuid => "Uuid"
      )
    ])
  end

  it "renders a list of deposits" do
    render
    assert_select "tr>td", :text => "Uuid".to_s, :count => 2
  end
end
