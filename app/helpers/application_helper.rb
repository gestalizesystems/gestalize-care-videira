module ApplicationHelper
  include Pagy::Frontend

  BADGE_CLASSES = {
    booking_group: {
      "pending"   => "badge-warning",
      "confirmed" => "badge-success",
      "cancelled" => "badge-neutral",
      "expired"   => "badge-danger"
    },
    payment: {
      "pending"   => "badge-warning",
      "paid"      => "badge-success",
      "failed"    => "badge-danger",
      "cancelled" => "badge-neutral",
      "expired"   => "badge-danger"
    }
  }.freeze

  def booking_group_status_badge(status)
    BADGE_CLASSES[:booking_group].fetch(status.to_s, "badge-neutral")
  end

  def payment_status_badge(status)
    BADGE_CLASSES[:payment].fetch(status.to_s, "badge-neutral")
  end

  # Linha de detalhe rótulo → valor (padrão das views de show/perfil).
  # Uso: <%= detail_row "E-mail", user.email %>
  # Uso: <%= detail_row "Nascimento", user.birth_date ? l(user.birth_date) : nil, border: false %>
  def detail_row(label, value, border: true)
    row_class = "flex justify-between py-3 text-sm"
    row_class += " border-b border-vdc-default" if border

    content_tag(:div, class: row_class) do
      content_tag(:span, label, class: "text-vdc-foreground") +
        content_tag(:span, value.presence || "—", class: "text-vdc-secondary")
    end
  end

  def money(cents)
    number_with_precision(cents / 100.0, precision: 2, delimiter: ".", separator: ",")
  end

  def format_cpf(value)
    digits = value.to_s.gsub(/\D/, "")
    return value if digits.length != 11
    "#{digits[0,3]}.#{digits[3,3]}.#{digits[6,3]}-#{digits[9,2]}"
  end

  def format_cro(value)
    v = value.to_s.upcase.gsub(/[^A-Z0-9]/, "").sub(/\ACRO/, "")
    letters = v.gsub(/[0-9]/, "")[0, 2].to_s
    digits  = v.gsub(/[A-Z]/, "")[0, 6].to_s
    return value if letters.blank? && digits.blank?
    out = "CRO-#{letters}"
    out += "#{letters.length == 2 ? ' ' : ''}#{digits}" if digits.present?
    out
  end

  def format_phone(value)
    digits = value.to_s.gsub(/\D/, "")
    case digits.length
    when 11 then "(#{digits[0,2]}) #{digits[2,5]}-#{digits[7,4]}"
    when 10 then "(#{digits[0,2]}) #{digits[2,4]}-#{digits[6,4]}"
    else value
    end
  end

  # Returns an inline onclick JS string to open a <dialog> by id.
  # Usage: onclick="<%= open_modal('my-dialog') %>"
  def open_modal(id)
    "document.getElementById('#{html_escape(id)}').showModal()"
  end
end
