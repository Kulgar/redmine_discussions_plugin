class CreateDiscussions < ActiveRecord::Migration[5.2]
  def change
    create_table :discussions do |t|
      t.string :subject
      t.text :content
      t.integer :author_id, foreign_key: true
      t.integer :priority_id, foreign_key: true
      t.belongs_to :project, foreign_key: true
    end
    add_index :discussions, :priority_id
    add_index :discussions, :author_id
  end
end
