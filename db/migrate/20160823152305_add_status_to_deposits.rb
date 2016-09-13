class AddStatusToDeposits < ActiveRecord::Migration
  def change
    add_column :deposits, :status, :string
  end
end
