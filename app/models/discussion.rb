class Discussion < ActiveRecord::Base
  has_many :answers, dependent: :destroy
  belongs_to :author, class_name: 'User', optional: false
  belongs_to :priority, class_name: 'IssuePriority', optional: true
  belongs_to :project, optional: true

  validates :subject, presence: true

  def visible?(user = User.current)
    !user.nil? && user.allowed_to?(:view_discussions, project)
  end

  def editable?(user = User.current)
    !user.nil? && user.allowed_to?(:add_discussion, project) &&
    (user.admin? || author_id == user.id)
  end

end
