class OnePublicRulebookVersionPerGame < ActiveRecord::Migration[7.1]
  def change
    add_index :rulebook_versions, :game_project_id,
              unique: true,
              where: "status = 1",
              name: "index_rulebook_versions_one_public_per_game"
  end
end
