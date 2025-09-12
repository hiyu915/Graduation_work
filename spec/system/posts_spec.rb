require 'rails_helper'

RSpec.describe "Posts", type: :system do

  describe 'マイページ' do
    let(:user) { create(:user) }
    let!(:post) { create(:post, user: user) }
    before { login(user) }
    
    context '正常系' do
      it 'マイページにアクセスした際に投稿が表示される' do
        visit posts_path

        expect(page).to have_content(post.visit_date.strftime('%Y-%m-%d'))
        expect(page).to have_content(post.shop_name)
        expect(page).to have_content(post.category.name)
        expect(page).to have_content(post.shop.location.prefecture.name)
        expect(page).to have_content(post.shop.location.city.name)
        expect(page).to have_content(post.companion.name)
        expect(page).to have_content(post.feeling.name)
        expect(page).to have_content(post.visit_reason.name)
      end
    end
  end

  describe '投稿新規作成' do
    let(:user) { create(:user) }
    before { login(user) }

    context '正常系' do
      it '新規投稿を作成できる/ 投稿内容が正しいか確認' do

        visit new_post_path

        fill_in 'post[shop_name]', with: '新規作成'
        fill_in 'post[visit_date]', with: '2025-1-1'
        fill_in 'post[body]', with: '新規投稿のメモ内容'

        image_path = Rails.root.join('spec/fixtures/files/test_image.jpg')
        attach_file 'post[post_image]', image_path, make_visible: true
        select '北海道', from: 'prefecture-select'
        sleep 1
        select 'えりも町', from: 'city-select'
        select 'イタリアン系', from: 'post[category_id]'
        select '友人', from: 'post[companion_id]'
        select 'ゆっくりしたい', from: 'post[feeling_id]'
        select 'たまたま', from: 'post[visit_reason_id]'

        click_button 'お店を記録する'
        sleep 3

        expect(current_path).to eq posts_path
        expect(page).to have_content('新規作成')
        expect(page).to have_content('イタリアン系')
        expect(page).to have_content('友人')
        expect(page).to have_content('ゆっくりしたい')
        expect(page).to have_content('たまたま')

        created_post = Post.last
        visit post_path(created_post)

        expect(page).to have_content('新規作成')
        expect(page).to have_content('イタリアン系')
        expect(page).to have_content('友人')
        expect(page).to have_content('ゆっくりしたい')
        expect(page).to have_content('たまたま')
        expect(page).to have_content('新規投稿のメモ内容')
        expect(page).to have_content('北海道')
        expect(page).to have_content('えりも町')
        created_post.reload
        expect(page).to have_css('img.img-fluid.rounded[style*="max-height: 400px"]')
      end
    end
  end

  describe '投稿詳細' do
    let(:user) { create(:user) }
    let!(:post) { create(:post, user: user) }
    before { login(user) }

    context '正常系' do
      it '詳細ページにアクセスした際に詳細が表示される' do
        visit post_path(post)
        expect(page).to have_content(post.visit_date.strftime('%Y年%m月%d日'))
        expect(page).to have_content(post.shop_name)
        expect(page).to have_content(post.category.name)
        expect(page).to have_content(post.shop.location.prefecture.name)
        expect(page).to have_content(post.shop.location.city.name)
        expect(page).to have_content(post.companion.name)
        expect(page).to have_content(post.feeling.name)
        expect(page).to have_content(post.visit_reason.name)
        expect(page).to have_content(post.body)

        expect(page).to have_css('img.img-fluid.rounded[style*="max-height: 400px"]')
      end

      it '詳細ページからマイページにアクセスした際に投稿が表示される' do
        visit post_path(post)
        link = find('a.btn-outline-secondary')
        link.click
        sleep 1
        expect(current_path).to eq posts_path
        expect(page).to have_content(post.visit_date.strftime('%Y-%m-%d'))
        expect(page).to have_content(post.shop_name)
        expect(page).to have_content(post.category.name)
        expect(page).to have_content(post.shop.location.prefecture.name)
        expect(page).to have_content(post.shop.location.city.name)
        expect(page).to have_content(post.companion.name)
        expect(page).to have_content(post.feeling.name)
        expect(page).to have_content(post.visit_reason.name)
      end

      it '詳細ページから編集ページにアクセスできる' do
        visit post_path(post)

        click_button id: 'postMenuButton'
        
        within '.dropdown-menu[aria-labelledby="postMenuButton"]' do
          click_link href: edit_post_path(post)
        end
        sleep 1
        expect(current_path).to eq edit_post_path(post)
      end
    end
  end

  describe '投稿編集' do
    let(:user) { create(:user) }
    let!(:post) { create(:post, user: user) }
    before { login(user) }

    context '正常系' do
      it '編集ページにアクセスした際に編集項目埋まった状態で表示される' do
        visit edit_post_path(post)
        expect(find('#post_visit_date').value).to eq post.visit_date.strftime('%Y-%m-%d')
        expect(find('#post_category_id').value).to eq post.category.id.to_s
        expect(find('#prefecture-select').value).to eq post.shop.location.prefecture.id.to_s
        expect(find('#city-select').value).to eq post.shop.location.city.id.to_s
        expect(find('#post_companion_id').value).to eq post.companion.id.to_s
        expect(find('#post_feeling_id').value).to eq post.feeling.id.to_s
        expect(find('#post_visit_reason_id').value).to eq post.visit_reason.id.to_s
        expect(find('#post_body').value).to eq post.body
      end
      
      it '投稿を編集して保存した場合、詳細ページに編集した投稿が表示される' do
        visit edit_post_path(post)

        fill_in 'post[shop_name]', with: '編集後のお店名'
        fill_in 'post[visit_date]', with: '2025-12-25'
        fill_in 'post[body]', with: '編集後のメモ内容'

        image_path = Rails.root.join('spec/fixtures/files/test_image.jpg')
        attach_file 'post[post_image]', image_path, make_visible: true

        select '大阪府', from: 'prefecture-select'
        sleep 1
        select '大阪市', from: 'city-select'
        select '中華系', from: 'post[category_id]'
        select 'カップル', from: 'post[companion_id]'
        select 'がっつり食べたい', from: 'post[feeling_id]'
        select 'インスタ', from: 'post[visit_reason_id]'

        click_button 'お店を保存する'
        sleep 3

        expect(current_path).to eq post_path(post)
        expect(page).to have_content('編集後のお店名')
        expect(page).to have_content('編集後のメモ内容')
        expect(page).to have_content('中華系')
        expect(page).to have_content('カップル')
        expect(page).to have_content('がっつり食べたい')
        expect(page).to have_content('インスタ')
        expect(page).to have_content('大阪府')
        expect(page).to have_content('大阪市')

        expect(page).to have_css('img')
        expect(page).to have_content('投稿を更新しました')

        post.reload
        expect(post.post_image).to be_present
      end
    end
  end
  describe '写真削除' do
    let(:user) { create(:user) }
    before { login(user) }
    it '新規作成後、写真が削除できるか' do
      visit new_post_path

      fill_in 'post[shop_name]', with: '写真削除テスト'
      fill_in 'post[visit_date]', with: '2025-1-1'
      fill_in 'post[body]', with: '新規投稿のメモ内容'

      image_path = Rails.root.join('spec/fixtures/files/test_image.jpg')
      attach_file 'post[post_image]', image_path, make_visible: true
      select '北海道', from: 'prefecture-select'
      sleep 1
      select 'えりも町', from: 'city-select'
      select 'イタリアン系', from: 'post[category_id]'
      select '友人', from: 'post[companion_id]'
      select 'ゆっくりしたい', from: 'post[feeling_id]'
      select 'たまたま', from: 'post[visit_reason_id]'

      click_button 'お店を記録する'
      sleep 3
      created_post = Post.last
      visit edit_post_path(created_post)
      expect(page).to have_content('写真を削除')
      sleep 1
      page.accept_confirm('写真を削除しますか？') do
        click_button '写真を削除'
      end
      sleep 1
      expect(current_path).to eq post_path(created_post)
      expect(page).to have_content('投稿を更新しました')
      expect(page).not_to have_css('img.post-image')
    end
  end

  describe '投稿削除' do
    let(:user) { create(:user) }
    let!(:post) { create(:post, user: user) }
    before { login(user) }

    context '正常系' do
      it '詳細ページから投稿を削除できる' do
        visit post_path(post)
        
        click_button id: 'postMenuButton'
        
        within '.dropdown-menu[aria-labelledby="postMenuButton"]' do
        accept_confirm do
          click_link href: post_path(post)
        end
    end
        sleep 1
        expect(current_path).to eq posts_path
        expect(page).to have_content('投稿を削除しました')
        expect(Post.exists?(post.id)).to be_falsey
      end
    end
  end
end