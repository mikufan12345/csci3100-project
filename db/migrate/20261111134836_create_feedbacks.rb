class CreateFeedbacks < ActiveRecord::Migration[7.1]
  def change
    create_table :feedbacks do |t|
      t.references :playtest_session, null: false, foreign_key: true
      t.references :rule_module, null: false, foreign_key: true
      t.integer :status
      t.text :comments

      t.timestamps
    end
  end
end
