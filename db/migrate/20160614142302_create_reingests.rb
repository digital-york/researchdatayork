class CreateReingests < ActiveRecord::Migration
  def change
    create_table :reingests do |t|
      t.timestamps null: false
    end
  end
end
