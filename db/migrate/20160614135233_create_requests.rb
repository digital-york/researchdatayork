class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.string :email
      t.string :name

      t.timestamps null: false
    end
  end
end
