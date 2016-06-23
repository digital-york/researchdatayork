class AddDipuuidToDeposits < ActiveRecord::Migration
  def change
    add_column :deposits, :dipuuid, :string
  end
end
