
class BadPost < ActiveRecord::Base
  belongs_to :category
  has_many :bad_tags
end