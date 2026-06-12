class ReplaceMercadopagoWithInfinitepay < ActiveRecord::Migration[7.2]
  def change
    # Troca colunas Pix do MercadoPago por URL de checkout do InfinitePay
    remove_column :payments, :pix_qr_code, :text
    remove_column :payments, :pix_qr_url,  :string
    add_column    :payments, :checkout_url, :string

    # Muda o default do gateway para infinitepay
    change_column_default :payments, :gateway, from: "mercadopago", to: "infinitepay"
  end
end
