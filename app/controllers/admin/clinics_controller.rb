class Admin::ClinicsController < Admin::BaseController
  def show
    @clinic = current_user.clinic
  end

  def update
    @clinic = current_user.clinic

    if @clinic.update(clinic_params)
      redirect_to admin_clinic_path(@clinic), notice: "Dados da clínica atualizados."
    else
      redirect_to admin_clinic_path(@clinic), alert: @clinic.errors.full_messages.to_sentence
    end
  end

  private

  def clinic_params
    params.require(:clinic).permit(:name, :phone, :email, :logo)
  end
end
