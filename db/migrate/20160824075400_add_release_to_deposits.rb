class AddReleaseToDeposits < ActiveRecord::Migration
  def change
    add_column :deposits, :release, :string
  end
end
