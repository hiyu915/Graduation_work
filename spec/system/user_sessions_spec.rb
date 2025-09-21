require 'rails_helper'

RSpec.describe 'UserSessions', type: :system do
  let(:user) { create(:user) }

  describe 'ログイン前' do
    context 'フォームの入力値が正常' do
      it 'ログイン処理が成功する' do
        visit login_path
        fill_in 'email', with: user.email
        fill_in 'password', with: 'password000'
        click_button 'ログイン'

        expect(page).to have_content('ログインしました')
        expect(current_path).to eq posts_path
      end
    end

    context 'フォームが未入力' do
      it 'ログイン処理が失敗する' do
        visit login_path
        fill_in 'email', with: ''
        fill_in 'password', with: ''
        click_button 'ログイン'

        expect(page).to have_content('ログインに失敗しました')
        expect(current_path).to eq login_path
      end
    end
  end

  describe 'ログイン後' do
    before do
      visit login_path
      fill_in 'email', with: user.email
      fill_in 'password', with: 'password000'
      click_button 'ログイン'
    end

    context 'ログアウト' do
      it 'ログアウト処理が成功する' do
        find('#accountDropdown').click

        expect(page).to have_css('.dropdown-menu', visible: true)

        within('.dropdown-menu') do
          click_link 'ログアウト'
        end

        # ログアウト後の確認
        expect(page).to have_content('ログアウトしました')
        expect(current_path).to eq root_path
        expect(page).to have_link('ログイン')
        expect(page).not_to have_css('#accountDropdown')
      end
    end
  end
end
