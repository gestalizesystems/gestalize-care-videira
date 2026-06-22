class Admin::ExtrasController < Admin::BaseController
  before_action :set_extra, only: [:destroy]

  def index
    @extras = current_clinic.extras.active.ordered
  end

  def create
    @extra = current_clinic.extras.new(extra_params)
    if @extra.save
      redirect_to admin_extras_path, notice: "Insumo criado."
    else
      redirect_to admin_extras_path, alert: @extra.errors.full_messages.to_sentence
    end
  end

  def destroy
    @extra.destroy!
    redirect_to admin_extras_path, notice: "Insumo removido."
  end

  private

  def set_extra
    @extra = current_clinic.extras.find(params[:id])
  end

  def extra_params
    p = params.require(:extra).permit(:name, :price)
    p[:price_cents] = price_to_cents(p.delete(:price))
    p
  end
end
