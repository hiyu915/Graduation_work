FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user_#{n}@example.com" }
    password { "password000" }
    password_confirmation { "password000" }
  end
end
