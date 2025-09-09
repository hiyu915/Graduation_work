# ファクトリで作成したオブジェクトが正しく生成されるか確認するテスト
require 'rails_helper'

RSpec.describe "Factories" do
  it "creates valid user" do
    user = create(:user)
    expect(user).to be_valid
  end

  it "creates valid shop with location" do
    shop = create(:shop)
    expect(shop).to be_valid
    expect(shop.location).to be_present
  end

  it "creates valid post" do
    post = create(:post)
    expect(post).to be_valid
    expect(post.user).to be_present
    expect(post.shop).to be_present
  end
end
