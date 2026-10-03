class User < ApplicationRecord
  # No public sign up and no password reset: the single account is created by db/seeds.rb.
  devise :database_authenticatable, :rememberable, :validatable

  has_many :dogs, dependent: :destroy
end
