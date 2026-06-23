# Serviço extra que o cliente pode adicionar ao carrinho além do turno
# (ex.: Filmaker). Gerenciado pelo admin; sincroniza com o carrinho do cliente.
class Extra < ApplicationRecord
  include MoneyConvertible
  money_field :price

  has_paper_trail

  belongs_to :clinic

  validates :name,        presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  # session[:cart_extras] => { "<extra_id>" => 2 }  →  [[Extra, 2], ...]
  def self.from_session(hash)
    return [] if hash.blank?
    found = active.where(id: hash.keys).index_by { |e| e.id }
    hash.filter_map do |id, qty|
      qty = qty.to_i
      extra = found[id]
      [extra, qty] if extra && qty.positive?
    end
  end
end
