require "rails_helper"

describe User do
  it "test user" do
    expect(true).to be_truthy

    user = FactoryBot.create(:user)

    expect(user.email).to include("example.com")
  end
end
