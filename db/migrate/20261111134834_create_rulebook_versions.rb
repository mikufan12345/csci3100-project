class CreateRulebookVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :rulebook_versions do |t|
      t.references :game_project, null: false, foreign_key: true
      t.integer :version_number
      t.integer :status

      t.timestamps
    end
  end
end
