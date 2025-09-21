module LoginMacros
  # SystemSpec用のログインメソッド
  def login(user)
    visit login_path
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: 'password000'
    click_button 'ログイン'
    expect(page).to have_content('ログアウト')
  end

  # RequestSpec用のログインメソッド
  def login_as(user)
    post login_path, params: {
          email: user.email,
          password: "password000"
        }
    expect(response).to have_http_status(302)
    expect(response.location).not_to include('login')
  end
end
