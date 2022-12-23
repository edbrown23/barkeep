# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  roles                  :string           default([]), is an Array
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  ADMIN_ROLE = 'admin'.freeze

  def admin?
    roles.any? { |s| s == ADMIN_ROLE }
  end

  class << self
    def current_id=(id)
      Thread.current[:current_user_id] = id
      @current_user = nil
    end

    def current_id
      Thread.current[:current_user_id]
    end

    def current
      @current_user ||= find_by(id: current_id)
    end
  end
end
