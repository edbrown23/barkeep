RSpec.shared_context "basic users" do
  let(:test_user) { User.create!(email: 'test@email.com', password: 'password') }
end