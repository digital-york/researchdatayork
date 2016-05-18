require 'rails_helper'

RSpec.describe "deposits/edit", type: :view do
  before(:each) do
    @deposit = assign(:deposit, deposit.create!(
      :uuid => "MyString"
    ))
  end

  it "renders the edit deposit form" do
    render

    assert_select "form[action=?][method=?]", deposit_path(@deposit), "post" do

      assert_select "input#deposit_uuid[name=?]", "deposit[uuid]"
    end
  end
end
