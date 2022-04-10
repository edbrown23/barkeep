module UserScopable
  extend ActiveSupport::Concern

  included do
    scope :for_user, ->(user = nil) { where(user_id: user&.id || User.current&.id) }
  end
end