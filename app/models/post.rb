class Post < ApplicationRecord
  attachment :image
  belongs_to :user
  belongs_to :category, optional: true
  has_many :post_comments, dependent: :destroy
  has_many :post_hashtag_relations, dependent: :destroy
  has_many :hashtags, through: :post_hashtag_relations
  has_many :likes, dependent: :destroy
  has_many :view_counts, dependent: :destroy
  has_many :notifications, dependent: :destroy


  # スコープ設定---------------------------------------------------------------------------------------------------------------
  # created_atカラムを降順で取得する
  default_scope { order(created_at: :desc) }
  # deletedカラムがfalseであるものを取得する
  scope :sorted, -> { order(created_at: :desc) }
  scope :active, -> { where("posts.user_id IN (SELECT users.id FROM users WHERE users.is_deleted = 0)") }#boolean (0 = false, 1 = true)
  scope :default_order, -> { order("posts.created_at desc, posts.id desc") }
  scope :recent, -> { sorted.active }

  # バリデーション-------------------------------------------------------------------------------------------------------------
  validates :title, presence: true, length: { in: 1..200 }
  validates :introduction, presence: true, length: { in: 1..1500 }
  validates :assignment, presence: true, length: { in: 1..1500 }
  validates :target, presence: true, length: { in: 1..200 }

  # 投稿に対する通知機能-----------------------------------------------------------いいね-------------------------------------
  def create_notification_like!(current_user)
    notifications = Notification.where(["visitor_id = ? and visited_id = ? and post_id = ? and action = ? ", current_user.id, user_id, id, 'like'])
    if notifications.blank?
      notification = current_user.active_notifications.new(post_id: id, visited_id: user_id, action: 'like')
      if notification.visitor_id == notification.visited_id
        notification.checked = true
      end
      notification.save if notification.valid?
    end
  end
  # 投稿に対する通知機能-----------------------------------------------------------コメント-------------------------------------
  def create_notification_comment!(current_user, post_comment_id)
    notifications_ids = PostComment.select(:user_id).where(post_id: id).where.not(user_id: current_user.id).distinct
    notifications_ids.each do |notification_id|
      save_notification_comment!(current_user, post_comment_id, notification_id['user_id'])
    end
    save_notification_comment!(current_user, post_comment_id, user_id) if temp_ids.blank?
  end

  def save_notification_comment!(current_user, post_comment_id, visited_id)
    notification = current_user.active_notifications.new(post_id: id, post_comment_id: post_comment_id, visited_id: visited_id, action: 'comment')
    if notification.visitor_id == notification.visited_id
      notification.checked = true
    end
    notification.save if notification.valid?
  end
  # ハッシュタグ機能-----------------------------------------------------------------------------------------------------------
  after_create do
    post = Post.find_by(id: self.id)
    hashtags = self.target.scan(/[#＃][\w\p{Han}ぁ-ヶｦ-ﾟー]+/)
    post.hashtags = []
    hashtags.uniq.map do |hashtag|
      tag = Hashtag.find_or_create_by(hashname: hashtag.downcase.delete('#'))#小文字化し＃を削除の後hashnameに代入
      post.hashtags << tag
    end
  end
  before_update do
    post = Post.find_by(id: self.id)
    post.hashtags.clear
    hashtags = self.target.scan(/[#＃][\w\p{Han}ぁ-ヶｦ-ﾟー]+/)
    hashtags.uniq.map do |hashtag|
      tag = Hashtag.find_or_create_by(hashname: hashtag.downcase.delete('#'))
      post.hashtags << tag
    end
  end
  # いいね機能----------------------------------------------------------------------------------------------------------------
  def liked_by?(user)
    likes.includes(:user).where(user_id: user.id).exists?
  end
  # 検索機能star--------------------------------------------------------------------------------------------------------------
  def self.search(search, word)
    if search == "perfect_match"#完全一致
      @post = Post.where("title LIKE? OR introduction LIKE OR target LIKE OR category LIKE", "#{word}","#{word}","#{word}","#{word}")
    elsif search == "forward_match"#前一致
      @post = Post.where("title LIKE? OR introduction LIKE OR target LIKE OR category LIKE", "#{word}%","#{word}%","#{word}%","#{word}")
    elsif search == "backward_match"#後ろ一致
      @post = Post.where("title LIKE? OR introduction LIKE OR target LIKE OR category LIKE", "%#{word}","%#{word}","%#{word}","#{word}")
    elsif search == "patial_match"#部分一致
      @post = Post.where("title LIKE? OR introduction LIKE OR target LIKE OR category LIKE", "%#{word}%","%#{word}%","%#{word}%","#{word}")
    else
      @post = Post.all
    end
  end
end
