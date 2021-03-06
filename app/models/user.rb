class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  attachment :profile_image#画像refile用

  # アソシエーション------------------------------------------------------------------------------------------------------------
  has_many :posts, dependent: :destroy#投稿
  has_many :posts_comments, dependent: :destroy#コメント
  has_many :likes, dependent: :destroy#いいね
  has_many :direct_messages, dependent: :destroy#DMの中間テーブル
  has_many :entries, dependent: :destroy#DMの中間テーブル
  has_many :rooms, through: :entries#中間テーブルEntryを通ってuser取得
  has_many :relationships, foreign_key: :following_id
  has_many :reverse_of_relationships, class_name: "Relationship", foreign_key: :follower_id
  has_many :followings, through: :relationships, source: :follower
  has_many :followers, through: :reverse_of_relationships, source: :following
  has_many :active_notifications, class_name: 'Notification', foreign_key: 'visitor_id', dependent: :destroy#active_notifications：自分からの通知
  has_many :passive_notifications, class_name: 'Notification', foreign_key: 'visited_id', dependent: :destroy#passive_notifications：相手からの通知
  has_many :events, dependent: :destroy#スケジュール機能


  default_scope { order(created_at: :desc) }
  # deletedカラムがfalseであるものを取得する
  scope :active, -> { where(is_deleted: false) }
  # created_atカラムを降順で取得する
  scope :sorted, -> { order(created_at: :desc) }
  # activeとsortedを合わせたもの
  scope :recent, -> { active.sorted }

  # バリデーション-------------------------------------------------------------------------------------------------------------
  validates :name, presence: true, length: { in: 1..50 }
  validates :introduction, presence: true, on: :update
  validates :introduction, length: {in: 1..300 }, on: :update


  def is_followed_by?(user)# フォローしてたらtrueを返す
    followings.include?(user)# find_byよりincludeの方がN＋１問題を解消できる
  end

  #フォロー通知機能-----------------------------------------------------------------------------------------------------
  def create_notification_follow!(current_user)
    followed_notifications = Notification.where(["visitor_id = ? and visited_id = ? and action = ? ",current_user.id, id, 'follow'])
    if followed_notifications.blank?
      notification = current_user.active_notifications.new(visited_id: id, action: 'follow')
      notification.save if notification.valid?
    end
  end
  # ユーザー検索機能-------------------------------------------------------------------------------------------------------
  def self.search(search, word)
    if search == "perfect_match"#完全一致
      @user = User.where("name LIKE? OR company LIKE", "#{word}","#{word}")
    elsif search == "forward_match"#前一致
      @user = User.where("name LIKE? OR company LIKE", "#{word}%","#{word}%")
    elsif search == "backward_match"#後ろ一致
      @user = User.where("name LIKE? OR company LIKE", "%#{word}","%#{word}")
    elsif search == "partial_match"#後ろ一致
      @user = User.where("name LIKE? OR company LIKE", "%#{word}%","%#{word}%")
    else
      @user = User.all
    end
  end
end
