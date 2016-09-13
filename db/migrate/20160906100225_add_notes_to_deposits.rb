class AddNotesToDeposits < ActiveRecord::Migration
  def change
    add_column :deposits, :notes, :string
  end
end
