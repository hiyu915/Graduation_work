require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    context '正常なケース' do
      it 'すべての属性が有効であること' do
        user = build(:user)
        expect(user).to be_valid
      end
    end

    context 'emailのバリデーション' do
      it 'emailが空の場合はバリデーションエラーになること' do
        user = build(:user, email: '')
        expect(user).to be_invalid
        expect(user.errors[:email]).to include('を入力してください')
      end

      it 'emailが重複している場合はバリデーションエラーになること' do
        create(:user, email: 'test@example.com')
        user = build(:user, email: 'test@example.com')
        expect(user).to be_invalid
        expect(user.errors[:email]).to include('はすでに存在します')
      end
    end

    context 'passwordのバリデーション' do
      it 'passwordが3文字未満の場合はバリデーションエラーになること' do
        user = build(:user, password: 'ab', password_confirmation: 'ab')
        expect(user).to be_invalid
        expect(user.errors[:password]).to include('は3文字以上で入力してください')
      end

      it 'password_confirmationが一致しない場合はバリデーションエラーになること' do
        user = build(:user, password: 'password123', password_confirmation: 'different')
        expect(user).to be_invalid
        expect(user.errors[:password_confirmation]).to include('とパスワードの入力が一致しません')
      end
    end
  end

  describe 'アソシエーション' do
    let(:user) { create(:user) }

    it 'postsと関連していること' do
      expect(user.posts).to eq([])
    end

    it 'favoritesと関連していること' do
      expect(user.favorites).to eq([])
    end

    it 'visitsと関連していること' do
      expect(user.visits).to eq([])
    end

    it 'authenticationsと関連していること' do
      expect(user.authentications).to eq([])
    end
  end

  describe 'dependent: :destroy' do
    let!(:user) { create(:user) }

    it 'ユーザーが削除されるとpostsも削除されること' do
      # ユーザーに関連するpostを作成
      post1 = create(:post, user: user)
      post2 = create(:post, user: user)

      # 他のユーザーのpostも作成（削除されないことを確認）
      other_user = create(:user)
      other_post = create(:post, user: other_user)

      # ユーザー削除前の状態確認
      expect(Post.count).to eq(3)
      expect(user.posts.count).to eq(2)

      # ユーザーを削除すると、関連するpostも削除される
      expect { user.destroy }.to change { Post.count }.from(3).to(1)

      # 他のユーザーのpostは残っている
      expect(Post.exists?(other_post.id)).to be true
      # 削除されたユーザーのpostは存在しない
      expect(Post.exists?(post1.id)).to be false
      expect(Post.exists?(post2.id)).to be false
    end

    it 'ユーザーが削除されるとfavoritesも削除されること' do
      favorite1 = create(:favorite, user: user)
      favorite2 = create(:favorite, user: user)

      expect { user.destroy }.to change { Favorite.count }.by(-2)
    end

    it 'ユーザーが削除されるとvisitsも削除されること' do
      visit1 = create(:visit, user: user)
      visit2 = create(:visit, user: user)

      expect { user.destroy }.to change { Visit.count }.by(-2)
    end
  end

  describe 'メール変更機能' do
    let(:user) { create(:user) }

    it 'generate_email_change_token!でトークンが生成されること' do
      new_email = 'new@example.com'
      user.send(:generate_email_change_token!, new_email)

      expect(user.unconfirmed_email).to eq(new_email)
      expect(user.email_change_token).to be_present
      expect(user.email_change_token_expires_at).to be_present
    end
  end
end
