class CreatePlaytestSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :playtest_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :rulebook_version, null: false, foreign_key: true
      t.integer :playtime_minutes
      t.integer :scenarios_completed

      t.timestamps
    end
  end
end
