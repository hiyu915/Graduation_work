require 'rails_helper'

RSpec.describe "PostAPI", type: :request do
  describe '全てのポストを取得する' do
  let(:user) { create(:user) }
  let!(:post_record) { create(:post, user: user) }
  before do
    login_as(user)
  end
    it '全てのポストを取得する' do
      get api_v1_posts_path, as: :json
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
    end

    it '特定のpostを取得する' do
      get "/api/v1/posts/#{post_record.id}", as: :json
      json = JSON.parse(response.body)

      expect(response.status).to eq(200)

      expect(json['data']['shop_name']).to eq(post_record.shop_name)
    end

    it '新しいpostを作成する' do
      valid_params = attributes_for(:post)
      #データが作成されている事を確認
      expect {
      post '/api/v1/posts', params: { post: valid_params }
    }.to change(Post, :count).by(1)
      # リクエスト成功を表す200が返ってきたか確認する。
      expect(response.status).to eq(200)
    end
    
    it 'postの編集を行う' do
      # 編集前の値を確認（デバッグ用）
      puts "編集前: shop_name=#{post_record.shop_name}, body=#{post_record.body}"
      
      put "/api/v1/posts/#{post_record.id}", 
          params: { 
            post: { 
              shop_name: 'new-shop-name',
              body: 'updated content',
              visit_date: '2024-01-05',
              category_id: 2,
              companion_id: 2,
              feeling_id: 2,
              visit_reason_id: 2,
            }
          },
          as: :json
      
      json = JSON.parse(response.body)

      # レスポンスの確認
      expect(response.status).to eq(200)
      expect(json['data']['shop_name']).to eq('new-shop-name')
      expect(json['data']['body']).to eq('updated content')
      expect(json['data']['visit_date']).to eq('2024-01-05')
      expect(json['data']['category_id']).to eq(2)
      expect(json['data']['companion_id']).to eq(2)
      expect(json['data']['feeling_id']).to eq(2)
      expect(json['data']['visit_reason_id']).to eq(2)
      expect(json['status']).to eq('success')
      
      # データベースでの更新確認
      post_record.reload
      expect(post_record.shop_name).to eq('new-shop-name')
      expect(post_record.body).to eq('updated content')
      expect(json['data']['visit_date']).to eq('2024-01-05')
      expect(json['data']['category_id']).to eq(2)
      expect(json['data']['companion_id']).to eq(2)
      expect(json['data']['feeling_id']).to eq(2)
      expect(json['data']['visit_reason_id']).to eq(2)
      expect(json['status']).to eq('success')
      
      # 編集後の値を確認（デバッグ用）
      puts "編集後: #{post_record.attributes.slice(
        'shop_name',
        'body',
        'visit_date',
        'category_id',
        'companion_id',
        'feeling_id',
        'visit_reason_id'
      )}"
    end

    it 'postの削除を行う' do
      # 削除前の投稿数を確認
      expect {
        delete "/api/v1/posts/#{post_record.id}", as: :json
      }.to change(Post, :count).by(-1)
      
      json = JSON.parse(response.body)

      # レスポンスの確認
      expect(response.status).to eq(200)
      expect(json['status']).to eq('success')
      expect(json['message']).to eq('Post deleted successfully')
      
      # データベースから削除されていることを確認
      expect(Post.find_by(id: post_record.id)).to be_nil
    end
  end
end