FactoryBot.define do
  factory :visit do
    association :user
    association :shop

    visited_at { Time.current }
  end
end
