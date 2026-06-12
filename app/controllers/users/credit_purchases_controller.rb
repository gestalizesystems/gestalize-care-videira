class Users::CreditPurchasesController < ApplicationController
  def create
    amount_cents = (params[:amount].to_s.gsub(/[^\d.,]/, "").tr(",", ".").to_f * 100).round

    if amount_cents <= 0
      return redirect_to carteira_path, alert: "Informe um valor válido."
    end

    clinic = current_user.clinic
    return redirect_to carteira_path, alert: "Sua conta não está associada a uma clínica." unless clinic

    purchase = CreditPurchase.create!(user: current_user, clinic: clinic, amount_cents: amount_cents)

    result = InfinitePay::CreditCheckoutCreator.call(credit_purchase: purchase)

    if result.success?
      purchase.update!(checkout_url: result.value[:checkout_url], expires_at: result.value[:expires_at])
      redirect_to result.value[:checkout_url], allow_other_host: true
    else
      purchase.update!(status: "cancelled")
      redirect_to carteira_path, alert: result.error
    end
  end
end
