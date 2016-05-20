class CreateDeposits < ActiveRecord::Migration
  def change
    create_table :deposits do |t|
      t.string :uuid
      t.string :title
      t.string :pure_uuid
      t.string :readme
      t.string :available
      t.string :embargo_end
      t.string :access

      t.timestamps null: false
    end
  end
end
