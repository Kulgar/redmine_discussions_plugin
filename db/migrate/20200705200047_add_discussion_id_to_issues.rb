class AddDiscussionIdToIssues < ActiveRecord::Migration[5.2]
  def change
    change_table :issues do |t|
      t.belongs_to :discussion, foreign_key: true
    end
  end
end
