require 'rails_helper'

RSpec.describe Shop, type: :model do
  describe 'バリデーション' do
    context '正常なケース' do
      it 'すべての属性が有効であること' do
        shop = FactoryBot.create(:shop)
        expect(shop).to be_valid
      end
    end

    context 'nameが空の場合' do
      it 'バリデーションエラーになること' do
        shop = build(:shop, name: '')
        expect(shop).to be_invalid
        expect(shop.errors[:name]).to include('を入力してください')
      end
    end
  end

  describe 'アソシエーション' do
    it 'locationと関連していること' do
      shop = create(:shop)
      expect(shop.location).to be_present
    end
  end
end
