class CreateAnswers < ActiveRecord::Migration[5.2]
  def change
    create_table :answers do |t|
      t.text :content
      t.belongs_to :discussion, foreign_key: true
      t.integer :author_id, foreign_key: true

      t.timestamps
    end
    add_index :answers, :author_id
  end
end
