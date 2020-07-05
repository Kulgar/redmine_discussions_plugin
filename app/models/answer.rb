class Answer < ActiveRecord::Base
  belongs_to :discussion, optional: false
  belongs_to :author, class_name: "User", optional: false
end
