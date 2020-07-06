class Answer < ActiveRecord::Base
  belongs_to :discussion, optional: false
  belongs_to :author, class_name: "User", optional: false

  validates :content, presence: true

  def self.creatable?(project, user = User.current)
    !user.nil? && user.allowed_to?(:answer_discussions, project)
  end

  def editable?(user = User.current)
    !user.nil? && user.allowed_to?(:answer_discussions, discussion.project) &&
    (user.admin? || author_id == user.id)
  end
end
