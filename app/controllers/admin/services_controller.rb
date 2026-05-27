class Admin::ServicesController < Admin::BaseController
  before_action :set_service, only: [:edit, :update, :destroy]

  def index
    @services = current_user.clinic.services.order(:name)
  end

  def new
    @service = Service.new
  end

  def create
    @service = current_user.clinic.services.new(service_params)
    if @service.save
      redirect_to admin_services_path, notice: "Serviço criado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @service.update(service_params)
      redirect_to admin_services_path, notice: "Serviço atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.update!(active: false)
    redirect_to admin_services_path, notice: "Serviço desativado."
  end

  private

  def set_service
    @service = current_user.clinic.services.find(params[:id])
  end

  def service_params
    p = params.require(:service).permit(:name, :duration_minutes, :price, :active)
    p[:price_cents] = (p.delete(:price).to_s.gsub(",", ".").to_f * 100).round if p[:price].present?
    p
  end
end
