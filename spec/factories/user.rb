FactoryBot.define do
  factory :user do
    sequence(:email) { |number| "user-#{number}@example.com" }
    password { 'password' }
  end
end
