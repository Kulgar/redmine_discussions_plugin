module Lgm
  module ProjectPatch
    extend ActiveSupport::Concern

    included do
      has_many :discussions, dependent: :destroy
    end
  end
end
