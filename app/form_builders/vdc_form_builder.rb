class VdcFormBuilder < ActionView::Helpers::FormBuilder
  # Renderiza label + campo dentro de <div> — padrão único para todos os formulários.
  #
  # Uso básico:
  #   f.vdc_field :name, "Nome"
  #   f.vdc_field :phone, "Telefone", :telephone_field
  #   f.vdc_field :price, "Preço (R$)", :number_field, min: 0, step: 0.01
  #   f.vdc_field :date,  "Data",      :date_field, class: "input-field w-full"
  #
  # O campo recebe automaticamente a classe .input-field.
  # Para sobrepor ou acrescentar classes, passe class: "..." — o valor substitui o padrão.
  def vdc_field(attribute, label_text, field_type = :text_field, **html_options)
    html_options = { class: "input-field" }.merge(html_options)

    @template.content_tag(:div) do
      label(attribute, label_text, class: "label") +
        send(field_type, attribute, html_options)
    end
  end
end
