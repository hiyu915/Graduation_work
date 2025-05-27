require 'csv'
require 'open-uri'
require 'zip'

DLURL           = "http://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip"
SAVEDIR         = "db/"
CSVROW_PREFNAME = 6
CSVROW_CITYNAME = 7

save_path = ""

# 郵便番号データ（ken_all.zip）をダウンロードし展開
URI.open(DLURL) do |file|
  Zip::File.open_buffer(file.read) do |zip_file|
    zip_file.each do |entry|
      save_path = File.join(SAVEDIR, entry.name)
      zip_file.extract(entry, save_path) { true }
    end
  end
end

# CSV を読み取り Prefecture / City モデルに登録
CSV.foreach(save_path, encoding: "Shift_JIS:UTF-8") do |row|
  prefecture_name = row[CSVROW_PREFNAME]
  city_name = row[CSVROW_CITYNAME]

  next if prefecture_name.blank? || city_name.blank?

  prefecture = Prefecture.find_or_create_by(name: prefecture_name)
  City.find_or_create_by(name: city_name, prefecture_id: prefecture.id)
end

# CSV ファイルを削除
File.delete(save_path) if File.exist?(save_path)

# カテゴリ
categories = [
  "イタリアン系", "カフェ・喫茶店", "カジュアル・手軽系", "スイーツ・デザート", "多国籍料理系",
  "中華系", "専門料理系", "バー・ダイニングバー", "ファストフード系", "フレンチ",
  "ベーカリー", "焼肉", "ラーメン", "レストラン", "和食系",
  "居酒屋", "その他"
]

categories.each do |name|
  Category.find_or_create_by!(name: name)
end

# 同行者
companions = [
  "1人", "友人", "カップル", "家族", "グループ",
  "会社", "同僚", "ママ友・パパ友", "その他"
]

companions.each do |name|
  Companion.find_or_create_by!(name: name)
end

# 気分
feelings = [
  "ゆっくりしたい", "がっつり食べたい", "わいわいしたい", "おしゃれに",
  "さっぱりヘルシーにしたい", "呑みたい", "しっとり落ち着きたい", "その他"
]

feelings.each do |name|
  Feeling.find_or_create_by!(name: name)
end

# 来店動機
visit_reasons = [
  "口コミ", "インスタ", "X(旧Twitter)", "TikTok", "紹介",
  "雑誌・メディア", "たまたま", "近かった", "記念日・お祝い", "その他"
]

visit_reasons.each do |name|
  VisitReason.find_or_create_by!(name: name)
end
