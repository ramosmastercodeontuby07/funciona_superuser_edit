# app/models/activity_log.rb
class ActivityLog < ApplicationRecord
  belongs_to :user

  validates :action, presence: true
  validates :details, presence: true
end
