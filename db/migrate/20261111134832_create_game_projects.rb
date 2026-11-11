class CreateGameProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :game_projects do |t|
      t.references :studio, null: false, foreign_key: true
      t.string :title

      t.timestamps
    end
  end
end
