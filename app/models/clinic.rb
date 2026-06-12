class Clinic < ApplicationRecord
  has_many :users
  has_many :services
  has_many :availabilities
  has_many :discount_rules
  has_many :booking_groups
  has_many :payments
  has_one_attached :logo

  validates :name,  presence: true
  validates :cnpj,  presence: true, uniqueness: true,
    format: { with: /\A\d{14}\z/, message: "deve conter 14 dígitos" }
  validates :phone, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
