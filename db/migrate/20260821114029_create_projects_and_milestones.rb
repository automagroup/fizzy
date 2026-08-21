class CreateProjectsAndMilestones < ActiveRecord::Migration[8.2]
  def change
    create_table :projects, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :board_id, null: false
      t.string :name, null: false
      t.date :due_on, null: false
      t.string :color, null: false

      t.timestamps

      t.index :account_id
      t.index [ :board_id, :due_on, :name ]
    end

    create_table :milestones, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :project_id, null: false
      t.string :name, null: false
      t.date :due_on, null: false

      t.timestamps

      t.index :account_id
      t.index [ :project_id, :due_on, :name ]
    end

    add_column :cards, :project_id, :uuid
    add_column :cards, :milestone_id, :uuid

    add_index :cards, [ :project_id, :milestone_id ]
    add_index :cards, :milestone_id
  end
end
