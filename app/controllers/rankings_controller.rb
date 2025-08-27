class RankingsController < ApplicationController
  def regional
    posts = current_user.posts

    # トップ情報
    @top_shop = posts.joins(:shop)
                     .group("shops.name")
                     .order("COUNT(posts.id) DESC")
                     .count
                     .first

    @top_month = posts.group("DATE_TRUNC('month', visit_date)")
                      .order("COUNT(posts.id) DESC")
                      .count
                      .first

    @top_category = posts.joins(:category)
                         .group("categories.name")
                         .order("COUNT(posts.id) DESC")
                         .count
                         .first

    @top_companion = posts.joins(:companion)
                          .group("companions.name")
                          .order("COUNT(posts.id) DESC")
                          .count
                          .first

    @top_feeling = posts.joins(:feeling)
                        .group("feelings.name")
                        .order("COUNT(posts.id) DESC")
                        .count
                        .first

    @top_visit_reason = posts.joins(:visit_reason)
                             .group("visit_reasons.name")
                             .order("COUNT(posts.id) DESC")
                             .count
                             .first

    # 一番行っている都道府県＋市（トップ1件のみ）
    top_region_hash = posts.joins(shop: { location: [:prefecture, :city] })
                           .group("prefectures.name", "cities.name")
                           .order("COUNT(posts.id) DESC")
                           .count
                           .first
    if top_region_hash
      (prefecture, city), count = top_region_hash
      @top_region = { region: "#{prefecture} #{city}", count: count }
    else
      @top_region = nil
    end
  end
end
