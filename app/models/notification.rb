class Notification < ApplicationRecord
  default_scope -> { order(created_at: :desc) }#作成日時の降順
  belongs_to :post, optional: true#optional: trueはnilを許可
  belongs_to :comment, optional: true#optional: trueはnilを許可

  belongs_to :visitor, class_name: 'User', foreign_key: 'visitor_id', optional: true
  belongs_to :visited, class_name: 'User', foreign_key: 'visited_id', optional: true
end
