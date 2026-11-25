class AddPriorityToFeedbacks < ActiveRecord::Migration[7.1]
  def change
    add_column :feedbacks, :priority, :integer, default: 0, null: false
  end
end
