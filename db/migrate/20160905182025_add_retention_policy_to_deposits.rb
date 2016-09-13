class AddRetentionPolicyToDeposits < ActiveRecord::Migration
  def change
    add_column :deposits, :retention_policy, :string
  end
end
