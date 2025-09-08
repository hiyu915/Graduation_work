module ApplicationHelper
  def page_title(title = "")
    base_title = "リピログ"
    title.present? ? "#{title} | #{base_title}" : base_title
  end

  def default_meta_tags(page_title_text = nil)
    {
      site: 'リピログ',
      title: page_title_text || 'リピログ',
      reverse: true,
      charset: 'utf-8',
      description: 'リピログは、「また行きたい」と思ったお店を中心に記録・整理できるグルメ記録アプリです。',
      keywords: 'グルメ, 記録, 食事, リピート',
      canonical: request.original_url,
      separator: '|',
      og: {
        site_name: :site,
        title: page_title_text || 'リピログ',
        description: :description,
        type: 'website',
        url: request.original_url,
        image: image_url('ogp.png'),
        local: 'ja-JP'
      },
      twitter: {
        card: 'summary_large_image',
        site: '@hiyuRUNTEQ',
        image: image_url('ogp.png')
      }
    }
  end
end
