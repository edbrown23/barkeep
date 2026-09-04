require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#admin?' do
    it 'recognizes the exact admin role' do
      expect(build(:user, roles: ['member', User::ADMIN_ROLE])).to be_admin
    end

    it 'does not treat similar role names as admin' do
      expect(build(:user, roles: ['administrator'])).not_to be_admin
    end
  end

  describe '.current' do
    it 'finds the user stored in the current thread' do
      user = create(:user)

      User.current_id = user.id

      expect(User.current).to eq(user)
    end

    it 'invalidates the memoized user when the id changes' do
      first_user = create(:user)
      second_user = create(:user)
      User.current_id = first_user.id
      User.current

      User.current_id = second_user.id

      expect(User.current).to eq(second_user)
    end

    it 'returns nil after the current id is cleared' do
      User.current_id = create(:user).id
      User.current

      User.current_id = nil

      expect(User.current).to be_nil
    end
  end
end
