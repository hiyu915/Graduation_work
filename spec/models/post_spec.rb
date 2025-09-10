require 'rails_helper'

RSpec.describe Post, type: :model do
  # seedデータの確保
  before(:all) do
    Rails.application.load_seed if Category.count.zero?
  end

  after(:each) do
    Post.destroy_all
    Shop.destroy_all
    # seedデータ（Category、Feeling等）は残す
  end

  describe 'バリデーション' do
    context '正常なケース' do
      it 'すべての属性が有効であること' do
        post = build(:post)
        expect(post).to be_valid
      end
    end

    context 'shop_nameのバリデーション' do
      it 'shop_nameが存在しない場合はバリデーションエラーになること' do
        post = build(:post, shop_name: nil)
        expect(post).to be_invalid
        expect(post.errors[:shop_name]).to include('を入力してください')
      end

      it 'shop_nameが空文字の場合はバリデーションエラーになること' do
        post = build(:post, shop_name: '')
        expect(post).to be_invalid
        expect(post.errors[:shop_name]).to include('を入力してください')
      end

      it 'shop_nameが100文字を超える場合はバリデーションエラーになること' do
        long_name = 'a' * 101
        post = build(:post, shop_name: long_name)
        expect(post).to be_invalid
        expect(post.errors[:shop_name]).to include('は100文字以内で入力してください')
      end

      it 'shop_nameが100文字ちょうどの場合は有効であること' do
        valid_name = 'a' * 100
        post = build(:post, shop_name: valid_name)
        expect(post).to be_valid
      end
    end

    context 'bodyのバリデーション' do
      it 'bodyが2000文字を超える場合はバリデーションエラーになること' do
        post = build(:post, :long_body)
        expect(post).to be_invalid
        expect(post.errors[:body]).to include('は2000文字以内で入力してください')
      end

      it 'bodyが2000文字ちょうどの場合は有効であること' do
        post = build(:post, :max_body)
        expect(post).to be_valid
      end

      it 'bodyが空でも有効であること' do
        post = build(:post, :empty_body)
        expect(post).to be_valid
      end

      it 'bodyがnilでも有効であること' do
        post = build(:post, :nil_body)
        expect(post).to be_valid
      end
    end

    context 'visit_dateのバリデーション' do
      it 'visit_dateが存在しない場合はバリデーションエラーになること' do
        post = build(:post, visit_date: nil)
        expect(post).to be_invalid
        expect(post.errors[:visit_date]).to include('を入力してください')
      end

      it 'visit_dateが過去の日付でも有効であること' do
        post = build(:post, visit_date: 1.year.ago)
        expect(post).to be_valid
      end

      it 'visit_dateが未来の日付でも有効であること' do
        post = build(:post, visit_date: 1.year.from_now)
        expect(post).to be_valid
      end
    end

    context '外部キーのバリデーション' do
      it 'user_idが存在しない場合はバリデーションエラーになること' do
        post = build(:post, user: nil)
        expect(post).to be_invalid
        expect(post.errors[:user]).to include('を入力してください')
      end

      it 'category_idが存在しない場合はバリデーションエラーになること' do
        post = build(:post, category_id: nil)
        expect(post).to be_invalid
        expect(post.errors[:category_id]).to include('を入力してください')
      end

      it 'feeling_idが存在しない場合はバリデーションエラーになること' do
        post = build(:post, feeling_id: nil)
        expect(post).to be_invalid
        expect(post.errors[:feeling_id]).to include('を入力してください')
      end

      it 'companion_idが存在しない場合はバリデーションエラーになること' do
        post = build(:post, companion_id: nil)
        expect(post).to be_invalid
        expect(post.errors[:companion_id]).to include('を入力してください')
      end

      it 'visit_reason_idが存在しない場合はバリデーションエラーになること' do
        post = build(:post, visit_reason_id: nil)
        expect(post).to be_invalid
        expect(post.errors[:visit_reason_id]).to include('を入力してください')
      end
    end
  end

  describe 'アソシエーション' do
    let(:post) { create(:post) }

    it 'userと関連していること' do
      expect(post.user).to be_present
      expect(post.user).to be_a(User)
    end

    it 'shopと関連していること' do
      expect(post.shop).to be_present
      expect(post.shop).to be_a(Shop)
    end

    it 'categoryと関連していること' do
      expect(post.category).to be_present
      expect(post.category).to be_a(Category)
    end

    it 'feelingと関連していること' do
      expect(post.feeling).to be_present
      expect(post.feeling).to be_a(Feeling)
    end

    it 'companionと関連していること' do
      expect(post.companion).to be_present
      expect(post.companion).to be_a(Companion)
    end

    it 'visit_reasonと関連していること' do
      expect(post.visit_reason).to be_present
      expect(post.visit_reason).to be_a(VisitReason)
    end

    describe 'favoritesとの関連' do
      it 'favoritesを複数持てること' do
        user1 = create(:user)
        user2 = create(:user)
        create(:favorite, post: post, user: user1)
        create(:favorite, post: post, user: user2)

        expect(post.favorites.count).to eq(2)
        expect(post.favorites.first).to be_a(Favorite)
      end

      it 'postが削除されるとfavoritesも削除されること' do
        create(:favorite, post: post)

        expect { post.destroy }.to change { Favorite.count }.by(-1)
      end
    end
  end

  describe 'コールバック' do
    describe '#assign_shop_id_from_name' do
      context 'shop_nameが設定されていてshop_idが空の場合' do
        it '新しいshopが作成されてshop_idが設定されること' do
          user = create(:user)
          # Location を事前に作成しておく（必要に応じて）
          location = Location.create!(prefecture_id: 1, city_id: 1)

          unique_shop_name = "新しいショップ#{SecureRandom.hex(4)}"

          post = Post.new(
            user: user,
            shop_name: unique_shop_name,
            visit_date: Date.new(2025, 9, 15),
            category_id: Category.first&.id,
            feeling_id: Feeling.first&.id,
            companion_id: Companion.first&.id,
            visit_reason_id: VisitReason.first&.id,
            body: "テスト投稿の本文です"
          )

          # デバッグ出力
          # puts "valid?: #{post.valid?}"
          # puts "errors: #{post.errors.full_messages}"

          expect {
            post.save!
          }.to change { Shop.count }.by(1)

          expect(post.shop).to be_present
          expect(post.shop.name).to eq(unique_shop_name)
          expect(post.shop.location_id).to eq(location.id)
          expect(post.shop_id).to be_present
        end
      end

      context 'shop_idが既に設定されている場合' do
        it '新しいshopは作成されないこと' do
          existing_shop = create(:shop, name: '既存ショップ')

          expect {
            create(:post, shop_name: '新しいショップ', shop_id: existing_shop.id)
          }.not_to change { Shop.count }

          post = Post.last
          expect(post.shop_id).to eq(existing_shop.id)
        end
      end

      context '同じ名前のshopが既に存在する場合' do
        it '既存のshopが使用されること' do
          existing_shop = create(:shop, name: '既存ショップ')

          expect {
            create(:post, shop_name: '既存ショップ', shop_id: nil)
          }.not_to change { Shop.count }

          post = Post.last
          expect(post.shop_id).to eq(existing_shop.id)
        end
      end
    end
  end

  describe 'スコープ' do
    describe '.latest_unique_by_shop_and_location' do
      let(:tokyo_location) { create(:location) }
      let(:osaka_location) { create(:location, :osaka) }
      let(:shop1) { create(:shop, location: tokyo_location) }
      let(:shop2) { create(:shop, location: osaka_location) }

      let!(:old_post) { create(:post, shop: shop1, visit_date: 1.month.ago) }
      let!(:new_post) { create(:post, shop: shop1, visit_date: 1.week.ago) }
      let!(:osaka_post) { create(:post, shop: shop2, visit_date: 2.weeks.ago) }

      it '店舗・場所ごとに最新の投稿のみが取得されること' do
        result = Post.latest_unique_by_shop_and_location

        expect(result).to include(new_post)  # shop1の最新
        expect(result).to include(osaka_post) # shop2の最新
        expect(result).not_to include(old_post) # shop1の古い投稿は除外
      end
    end

    describe '.by_category' do
      let(:category1) { Category.first }
      let(:category2) { Category.second }
      let!(:post1) { create(:post, category_id: category1.id) }
      let!(:post2) { create(:post, category_id: category2.id) }

      it '指定したカテゴリの投稿のみが取得されること' do
        result = Post.by_category(category1.id)

        expect(result).to include(post1)
        expect(result).not_to include(post2)
      end
    end

    describe '.recent' do
      let!(:recent_post) { create(:post, visit_date: 1.day.ago) }
      let!(:old_post) { create(:post, visit_date: 1.year.ago) }

      it '訪問日が新しい順で取得されること' do
        result = Post.recent

        expect(result.first).to eq(recent_post)
        expect(result.last).to eq(old_post)
      end
    end
  end

  describe 'インスタンスメソッド' do
    let(:post) { create(:post) }

    describe '#favorited_by?' do
      let(:user) { create(:user) }

      context 'ユーザーがお気に入りしている場合' do
        before { create(:favorite, user: user, post: post) }

        it 'trueを返すこと' do
          expect(post.favorited_by?(user)).to be true
        end
      end

      context 'ユーザーがお気に入りしていない場合' do
        it 'falseを返すこと' do
          expect(post.favorited_by?(user)).to be false
        end
      end
    end

    describe '#visited_by_user?' do
      let(:user) { create(:user) }
      let(:shop) { create(:shop) }
      let(:post) { create(:post, shop: shop) }

      before do
        Visit.destroy_all
      end

      context 'ユーザーが訪問済みの場合' do
        before { create(:visit, user: user, shop: shop) }

        it 'trueを返すこと' do
          expect(post.visited_by_user?(user)).to be true
        end
      end

      context 'ユーザーが未訪問の場合' do
        it 'falseを返すこと' do
          expect(post.visited_by_user?(user)).to be false
        end
      end

      after do
        Visit.destroy_all
      end
    end

    describe '#display_shop_name' do
      context 'shop_nameが設定されている場合' do
        it 'shop_nameを返すこと' do
          post.shop_name = 'カスタムショップ名'
          expect(post.display_shop_name).to eq('カスタムショップ名')
        end
      end

      context 'shop_nameが空でshopが関連している場合' do
        it 'shop.nameを返すこと' do
          post.shop_name = ''
          expect(post.display_shop_name).to eq(post.shop.name)
        end
      end
    end
  end

  describe 'クラスメソッド' do
    describe '.search' do
      let!(:post1) { create(:post, shop_name: 'ラーメン太郎', body: '美味しいラーメン') }
      let!(:post2) { create(:post, shop_name: 'カフェ花子', body: 'おしゃれな空間') }

      context 'shop_nameで検索' do
        it '該当する投稿が取得されること' do
          result = Post.search('ラーメン')

          expect(result).to include(post1)
          expect(result).not_to include(post2)
        end
      end

      context 'bodyで検索' do
        it '該当する投稿が取得されること' do
          result = Post.search('おしゃれ')

          expect(result).to include(post2)
          expect(result).not_to include(post1)
        end
      end

      context '検索文字列が空の場合' do
        it '全ての投稿が取得されること' do
          result = Post.search('')

          expect(result).to include(post1, post2)
        end
      end
    end
  end

  describe 'エラーハンドリング' do
    context '存在しないcategory_idを指定した場合' do
      it 'バリデーションエラーになること' do
        post = build(:post, category_id: 99999)
        expect(post).to be_invalid
        expect(post.errors[:category]).to include('を入力してください')
      end
    end

    context '存在しないfeeling_idを指定した場合' do
      it 'バリデーションエラーになること' do
        post = build(:post, feeling_id: 99999)
        expect(post).to be_invalid
        expect(post.errors[:feeling]).to include('を入力してください')
      end
    end

    context '存在しないcompanion_idを指定した場合' do
      it 'バリデーションエラーになること' do
        post = build(:post, companion_id: 99999)
        expect(post).to be_invalid
        expect(post.errors[:companion]).to include('を入力してください')
      end
    end

    context '存在しないvisit_reason_idを指定した場合' do
      it 'バリデーションエラーになること' do
        post = build(:post, visit_reason_id: 99999)
        expect(post).to be_invalid
        expect(post.errors[:visit_reason]).to include('を入力してください')
      end
    end
  end

  describe 'データ整合性' do
    describe 'トランザクション' do
      it 'shop作成とpost作成が同一トランザクションで実行されること' do
        # トランザクション前の件数を取得
        initial_post_count = Post.count
        initial_shop_count = Shop.count

        begin
          Post.transaction do
            create(:post, shop_name: 'トランザクションテスト', shop_id: nil)
            # 強制的にロールバック
            raise ActiveRecord::Rollback
          end
        rescue ActiveRecord::Rollback
          # 例外は無視
        end

        # トランザクション後、件数が変わっていないことを確認
        expect(Post.count).to eq(initial_post_count)
        expect(Shop.count).to eq(initial_shop_count)
      end
    end

    describe 'カスケード削除' do
      let!(:post) { create(:post) }
      let!(:favorite1) { create(:favorite, post: post) }
      let!(:favorite2) { create(:favorite, post: post) }

      it 'postが削除されると関連するfavoritesもすべて削除されること' do
        expect { post.destroy }.to change { Favorite.count }.by(-2)
      end

      it 'userが削除されるとそのユーザーのpostsも削除されること' do
        user = post.user
        expect { user.destroy }.to change { Post.count }.by(-1)
      end
    end
  end

  describe 'エッジケース' do
    context '極端に長いデータ' do
      it 'shop_nameが日本語で100文字の場合も正常に処理されること' do
        long_japanese_name = 'あ' * 100
        post = build(:post, shop_name: long_japanese_name)
        expect(post).to be_valid
      end

      it 'bodyが絵文字を含む場合も正常に処理されること' do
        emoji_body = '美味しかった😋🍜✨'
        post = build(:post, body: emoji_body)
        expect(post).to be_valid
      end
    end

    context '特殊文字の処理' do
      it 'shop_nameにHTMLタグが含まれていても正常に処理されること' do
        html_name = '<script>alert("test")</script>カフェ'
        post = build(:post, shop_name: html_name)
        expect(post).to be_valid
        expect(post.shop_name).to eq(html_name)
      end
    end

    context '日付の境界値' do
      it '1900年1月1日でも有効であること' do
        old_date = Date.new(1900, 1, 1)
        post = build(:post, visit_date: old_date)
        expect(post).to be_valid
      end

      it '2100年12月31日でも有効であること' do
        future_date = Date.new(2100, 12, 31)
        post = build(:post, visit_date: future_date)
        expect(post).to be_valid
      end
    end
  end
end
