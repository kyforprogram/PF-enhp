module Users::PostsHelper
  def render_with_hashtags(target)
    target.gsub(/[#＃][\w\p{Han}ぁ-ヶｦ-ﾟー]+/){|word| link_to word, "/post/hashtag/#{word.delete("#")}"}.html_safe
  end
end
