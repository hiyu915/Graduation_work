require 'rails_helper'

RSpec.describe 'Users', type: :system do
  let(:user) { create(:user) }

  describe 'ログイン前' do
    describe 'ユーザー新規登録' do
      context 'フォームの入力値が正常' do
        it 'ユーザーの新規作成が成功する' do
          visit new_user_path
          fill_in 'user_email', with: 'email@example.com'
          fill_in 'user_password', with: 'password'
          fill_in 'user_password_confirmation', with: 'password'
          find('input[type="submit"]').click
          expect(page).to have_content '確認メールを送信しました。メールをご確認ください。'
          expect(current_path).to eq root_path
        end
      end

      context 'メールアドレスが未入力' do
        it 'ユーザーの新規作成が失敗する' do
          visit new_user_path
          fill_in 'user_email', with: ''
          fill_in 'user_password', with: 'password'
          fill_in 'user_password_confirmation', with: 'password'
          find('input[type="submit"]').click
          expect(page).to have_content '会員登録に失敗しました'
          expect(page).to have_content "メールアドレスを入力してください"
          expect(current_path).to eq new_user_path
        end
      end   

      context '登録済のメールアドレスを使用' do
        it 'ユーザーの新規作成が失敗する' do
          existed_user = create(:user, email: 'test@example.com')
          visit new_user_path
          fill_in 'user_email', with: 'test@example.com'
          fill_in 'user_password', with: 'password'
          fill_in 'user_password_confirmation', with: 'password'
          find('input[type="submit"]').click
          
          expect(page).to have_content '会員登録に失敗しました'
          expect(page).to have_content 'メールアドレスはすでに存在します'
          expect(current_path).to eq new_user_path
          expect(page).to have_field 'user_email', with: 'test@example.com'
        end
      end
    end

    describe 'マイページ' do
      context 'ログインしていない状態' do
        it 'マイページへのアクセスが失敗する' do
          visit account_path
          expect(page).to have_content('ログインしてください')
          expect(current_path).to eq login_path
        end
      end
    end
  end

  describe 'ログイン後' do
    before { login(user) } 

    describe 'メールアドレス変更機能' do
      context 'フォームの入力値が正常' do
        it 'メールアドレス変更リクエストが成功する' do
          visit edit_email_users_path
          expect(page).to have_selector('h1', text: 'メールアドレス変更')
          fill_in 'user_unconfirmed_email', with: 'update@example.com'
          click_button '確認メールを送信'
          expect(page).to have_content('確認メールを送信しました')
        end
      end
    end

    describe 'アカウント情報表示' do
      it 'アカウント情報が表示される' do
        visit account_info_users_path 
        expect(page).to have_content(user.email)
      end
    end

    describe 'マイページ' do
      context '投稿を作成' do
        it '作成した投稿がマイページに表示される' do
          post = create(:post, user: user)
          
          visit posts_path

          expect(page).to have_content(post.visit_date.strftime('%Y-%m-%d'))
          expect(page).to have_content(post.shop_name)
          expect(page).to have_content(post.category.name)
          expect(page).to have_content(post.shop.location.prefecture.name)
          expect(page).to have_content(post.shop.location.prefecture.name)
          expect(page).to have_content(post.shop.location.city.name)        
          expect(page).to have_content(post.companion.name)
          expect(page).to have_content(post.feeling.name)
          expect(page).to have_content(post.visit_reason.name)
        end
      end
    end
  end
end
