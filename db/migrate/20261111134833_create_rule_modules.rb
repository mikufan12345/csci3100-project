class CreateRuleModules < ActiveRecord::Migration[7.1]
  def change
    create_table :rule_modules do |t|
      t.references :game_project, null: false, foreign_key: true
      t.string :title
      t.integer :deprecated

      t.timestamps
    end
  end
end
