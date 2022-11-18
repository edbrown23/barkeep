module UserScopable
  extend ActiveSupport::Concern

  included do
    belongs_to :user

    scope :for_user, ->(user = nil) { where(user_id: user&.id || User.current&.id) }
  end
end