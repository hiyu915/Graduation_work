FactoryBot.define do
  factory :post do
    association :user
    association :shop

    shop_name { "テストショップ" } 

    visit_date { Date.new(2025, 9, 15) }

    category_id { Category.first.id }
    feeling_id { Feeling.first.id }
    companion_id { Companion.first.id }
    visit_reason_id { VisitReason.first.id }

    body { "テスト投稿の本文です" }
    
    # 異なるパターンのトレイト
    trait :with_custom_date do
      visit_date { 1.week.ago }
    end
    
    trait :long_body do
      body { 'a' * 2001 }
    end
    
    trait :max_body do
      body { 'a' * 2000 }
    end
    
    trait :empty_body do
      body { '' }
    end
    
    trait :nil_body do
      body { nil }
    end

    trait :with_new_shop_name do
      after(:build) do |post, evaluator|
        post.shop_id = nil  # 既存のshop関連付けを無効化
      end
    end
  end
end