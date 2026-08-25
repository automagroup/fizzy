class CreateFiltersProjects < ActiveRecord::Migration[8.2]
  def change
    create_table :filters_projects, id: false do |t|
      t.uuid :filter_id, null: false
      t.uuid :project_id, null: false

      t.index :filter_id
      t.index :project_id
    end
  end
end
