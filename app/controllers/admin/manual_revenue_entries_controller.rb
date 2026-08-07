class Admin::ManualRevenueEntriesController < Admin::BaseController
  def create
    month  = parse_month(params[:month]) || Date.current.beginning_of_month
    client = current_user.clinic.users.where(role: "dentist").find_by(id: params[:client_id])

    if client.nil?
      return redirect_to admin_root_path(month: month.strftime("%Y-%m")),
        alert: "Selecione um cliente já cadastrado."
    end

    entry = ManualRevenueEntry.new(
      clinic:       current_user.clinic,
      client:       client,
      created_by:   current_user,
      amount_cents: price_to_cents(params[:amount]),
      category:     params[:category],
      month:        month
    )

    if entry.save
      redirect_to admin_root_path(month: month.strftime("%Y-%m")), notice: "Receita adicionada."
    else
      redirect_to admin_root_path(month: month.strftime("%Y-%m")), alert: entry.errors.full_messages.to_sentence
    end
  end

  private

  def parse_month(value)
    return nil if value.blank?
    Date.strptime(value, "%Y-%m").beginning_of_month
  rescue ArgumentError
    nil
  end
end
