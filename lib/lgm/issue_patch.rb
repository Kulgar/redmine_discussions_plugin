module Lgm
  module IssuePatch
    extend ActiveSupport::Concern

    included do
      belongs_to :discussion, optional: true

      safe_attributes('discussion_id',
        :if => lambda {|issue, user| issue.new_record? || issue.attributes_editable?(user)})
    end
  end
end
