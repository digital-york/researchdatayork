class CreateDeposits < ActiveRecord::Migration
  def change
    create_table :deposits do |t|
      t.string :uuid
      t.string :title
      t.string :people
      t.string :pure_uuid

      t.timestamps null: false
    end
  end
end
