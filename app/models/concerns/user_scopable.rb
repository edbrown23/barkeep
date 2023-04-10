module UserScopable
  extend ActiveSupport::Concern

  included do
    belongs_to :user, optional: true

    scope :for_user, ->(user = nil) { where(user_id: user&.id || User.current&.id) }
    scope :for_user_or_shared, ->(user = nil) { where(user_id: [(user&.id || User.current&.id), nil]) }
  end
end