FactoryBot.define do
  factory :location do
    prefecture { Prefecture.find_by(name: "東京都") }
    city { City.find_by(name: "渋谷区") }

    trait :osaka do
      prefecture { Prefecture.find_by(name: "大阪府") }
      city { City.find_by(name: "大阪市") }
    end

    trait :safe_default do
      prefecture { Prefecture.first || create(:prefecture, name: "テスト都道府県") }
      city { City.first || create(:city, name: "テスト市区町村") }
    end
  end
end
