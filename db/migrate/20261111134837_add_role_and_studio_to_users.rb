class AddRoleAndStudioToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :role, :integer
    add_reference :users, :studio, null: false, foreign_key: true
  end
end
