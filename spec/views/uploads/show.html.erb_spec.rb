require 'rails_helper'

RSpec.describe "deposits/show", type: :view do
  before(:each) do
    @deposit = assign(:deposit, deposit.create!(
      :uuid => "Uuid"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Uuid/)
  end
end
