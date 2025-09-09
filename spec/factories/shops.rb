FactoryBot.define do
  factory :shop do
    sequence(:name) { |n| "テストショップ#{n}" }
    location
  end
end
