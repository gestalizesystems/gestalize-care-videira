class User < ApplicationRecord
  include MoneyConvertible
  money_field :discount_per_slot

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_paper_trail

  validates :discount_per_slot_cents, numericality: { greater_than_or_equal_to: 0 }

  belongs_to :clinic, optional: true
  has_many :availabilities, foreign_key: :dentist_id, dependent: :nullify
  has_many :booking_groups, foreign_key: :dentist_id
  has_many :bookings,       foreign_key: :dentist_id

  enum :role, { owner: "owner", dentist: "dentist" }, default: "dentist"

  validates :name, presence: true
  validates :cpf,  uniqueness: true, allow_nil: true,
    format: { with: /\A\d{11}\z/, message: "deve conter 11 dígitos" }

  # Aceite dos termos obrigatório no cadastro por e-mail (nil = não validado:
  # logins via Google e atualizações de perfil não passam por aqui).
  attr_accessor :terms_accepted
  validates :terms_accepted, acceptance: { message: "É necessário aceitar os termos de uso para se cadastrar." }

  # Campos opcionais em branco viram nil (evita falhar a validação de formato)
  before_validation do
    self.cpf   = cpf.presence
    self.phone = phone.presence if respond_to?(:phone)
    self.cro   = cro.presence   if respond_to?(:cro)
  end

  scope :dentists, -> { where(role: "dentist") }

  # Cadastro completo: dentistas precisam de CPF, CRO e telefone preenchidos.
  # (Cadastro via Google não coleta esses dados, então exigimos depois.)
  def profile_complete?
    return true unless dentist?
    cpf.present? && cro.present? && phone.present?
  end

  def self.from_omniauth(auth)
    return nil if auth.info.email.blank?

    where(provider: auth.provider, uid: auth.uid).first_or_initialize do |u|
      u.email    = auth.info.email
      u.name     = auth.info.name.presence || auth.info.email.split("@").first
      u.password = Devise.friendly_token[0, 20]
      u.clinic ||= Clinic.first # sem clínica, o usuário some da listagem admin
      u.skip_confirmation! # e-mail já é verificado pela Google
    end.tap(&:save)
  end
end
