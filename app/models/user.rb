class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_paper_trail

  belongs_to :clinic, optional: true
  has_many :availabilities, foreign_key: :dentist_id, dependent: :nullify
  has_many :booking_groups, foreign_key: :dentist_id
  has_many :bookings,       foreign_key: :dentist_id
  has_one_attached :avatar

  enum :role, { owner: "owner", dentist: "dentist" }, default: "dentist"

  validates :name, presence: true
  validates :cpf,  uniqueness: true, allow_nil: true,
    format: { with: /\A\d{11}\z/, message: "deve conter 11 dígitos" }

  # Campos opcionais em branco viram nil (evita falhar a validação de formato)
  before_validation do
    self.cpf   = cpf.presence
    self.phone = phone.presence if respond_to?(:phone)
    self.cro   = cro.presence   if respond_to?(:cro)
  end

  scope :dentists, -> { where(role: "dentist") }

  def self.from_omniauth(auth)
    return nil if auth.info.email.blank?

    where(provider: auth.provider, uid: auth.uid).first_or_initialize do |u|
      u.email    = auth.info.email
      u.name     = auth.info.name.presence || auth.info.email.split("@").first
      u.password = Devise.friendly_token[0, 20]
      u.skip_confirmation! # e-mail já é verificado pela Google
    end.tap(&:save)
  end

  def avatar_url
    return nil unless avatar.attached? && avatar.blob&.persisted?
    Rails.application.routes.url_helpers.rails_blob_path(avatar, only_path: true)
  end
end
