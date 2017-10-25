class AddAuthorisedDepositorsToDeposits < ActiveRecord::Migration
  def change
    add_column :deposits, :authorised_depositors, :string
  end
end
