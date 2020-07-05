class Discussion < ActiveRecord::Base
  has_many :answers, dependent: :destroy
  belongs_to :author, class_name: 'User', optional: false
  belongs_to :priority, class_name: 'IssuePriority', optional: true
  belongs_to :project, optional: true

  validates :subject, presence: true
end
