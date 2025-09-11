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

    describe 'メールアドレス変更機能の認証' do
      context '未ログイン状態' do
        it 'メールアドレス変更ページにアクセスできない' do
          visit edit_email_users_path
          
          expect(page).to have_content('ログインしてください')
          expect(current_path).to eq login_path
        end
      end
    end
  end

  describe 'ログイン後' do
    describe 'メールアドレス変更機能' do
      let(:user) { create(:user) }
      before { login(user) }

      context 'フォームの入力値が正常' do
        it 'メールアドレス変更リクエストが成功する' do
          visit edit_email_users_path
          expect(page).to have_selector('h1', text: 'メールアドレス変更')
          
          fill_in 'user_unconfirmed_email', with: 'update@example.com'
          click_button '確認メールを送信'
          
          expect(page).to have_content('確認メールを送信しました')
        end
      end

      context 'フォームの入力値が異常' do
        it 'メールアドレスが空の場合、変更に失敗する' do
          visit edit_email_users_path
          fill_in 'user_unconfirmed_email', with: ''
          click_button '送信'
          
          expect(current_path).to eq edit_email_users_path
          expect(page).to have_content('メールアドレスを入力してください')
        end

        it '無効なメールアドレス形式の場合、変更に失敗する' do
          visit edit_email_users_path

          page.execute_script("document.querySelector('form').setAttribute('novalidate', 'novalidate')")
          
          fill_in 'user_unconfirmed_email', with: 'invalid-email'
          click_button '確認メールを送信'
          
          expect(page).to have_content('メールアドレスは不正な値です')
        end

        it '既に登録済みのメールアドレスの場合、変更に失敗する' do
          existing_user = create(:user, email: 'existing@example.com')
          
          visit edit_email_users_path
          fill_in 'user_unconfirmed_email', with: existing_user.email
          click_button '確認メールを送信'

          expect(page).to have_content('そのメールアドレスは既に使用されています')
        end

        describe 'パスワードリセット申請' do
          context 'フォームの入力値が正常' do
            it 'メールアドレス入力でリセット申請が成功する' do
              visit new_password_reset_path
              expect(page).to have_content('パスワードリセット申請')
              fill_in 'email', with: user.email
              click_button '送信'
              expect(page).to have_content('パスワードリセット手順を送信しました')
              expect(current_path).to eq login_path
            end
          end

          context 'フォームの入力値が異常' do
            it '存在しないメールアドレスでもリセット申請が受け付けられる（セキュリティ対策）' do
              visit new_password_reset_path
              fill_in 'email', with: 'nonexistent@example.com'
              click_button '送信'
              expect(page).to have_content('パスワードリセット手順を送信しました')
              expect(current_path).to eq login_path
            end

            it 'メールアドレスが空でもリセット申請が受け付けられる' do
              visit new_password_reset_path
              
              fill_in 'email', with: ''
              click_button '送信'
              
              expect(page).to have_content('パスワードリセット手順を送信しました')
              expect(current_path).to eq login_path
            end
          end
        end
      end
    end

    describe 'パスワードリセット機能', type: :system do
      let(:user) { create(:user) }

      context 'フォームの入力値が正常' do
        it 'メールアドレス入力でリセット申請が成功する' do
          visit new_password_reset_path
          expect(page).to have_content('パスワードリセット申請')
          fill_in 'email', with: user.email
          click_button '送信'
          expect(page).to have_content('パスワードリセット手順を送信しました')
          expect(current_path).to eq login_path
        end

        it 'パスワードリセットが成功する' do
          # リセットトークンを生成
          user.deliver_reset_password_instructions!
          reset_token = user.reset_password_token

          visit edit_password_reset_path(reset_token)
          expect(page).to have_content('パスワードリセット') 
          
          fill_in 'user_password', with: 'new_password123'
          fill_in 'user_password_confirmation', with: 'new_password123'
          click_button '更新'
          
          expect(page).to have_content('パスワードを変更しました') 
        end
      end

      context 'フォームの入力値が異常' do
        it 'パスワード確認が一致しない場合、変更に失敗する' do
          user.deliver_reset_password_instructions!
          reset_token = user.reset_password_token

          visit edit_password_reset_path(reset_token)
          
          fill_in 'user_password', with: 'new_password123'
          fill_in 'user_password_confirmation', with: 'different_password'
          click_button '更新'
          
          expect(page).to have_content('パスワード確認とパスワードの入力が一致しません')
        end

        it '短すぎるパスワードの場合、変更に失敗する' do
          user.deliver_reset_password_instructions!
          reset_token = user.reset_password_token

          visit edit_password_reset_path(reset_token)
          
          fill_in 'user_password', with: '12'
          fill_in 'user_password_confirmation', with: '12'
          click_button '更新'
          
          expect(page).to have_content('パスワードは3文字以上で入力してください')
        end
      end
    end

    describe 'アカウント情報表示' do
      let(:user) { create(:user) }
      before { login(user) }

      it 'アカウント情報が表示される' do
        visit account_info_users_path
        expect(page).to have_content(user.email)
      end
    end

    describe 'マイページ' do
      let(:user) { create(:user) }
      before { login(user) }
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
