
class Post < ActiveRecord::Base
  belongs_to :author, foreign_key: 'author_id', class_name: 'User'
  belongs_to :category
  has_many :post_tags
  has_many :tags, through: :post_tags
end