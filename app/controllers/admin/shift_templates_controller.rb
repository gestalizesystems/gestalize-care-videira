class Admin::ShiftTemplatesController < Admin::BaseController
  before_action :set_template, only: [:destroy, :toggle]

  def index
    @templates = current_clinic.shift_templates.to_a
      # Diárias primeiro, depois os demais — cada grupo ordenado por horário local.
      .sort_by { |t| [t.diaria? ? 0 : 1, t.starts_at.strftime("%H:%M")] }
  end

  def create
    @template = current_clinic.shift_templates.new(template_params)
    if @template.save
      RecurringShifts::Generator.fill_template(@template)
      redirect_to admin_shift_templates_path,
        notice: "Turno padrão criado — já aplicado aos próximos dias."
    else
      redirect_to admin_shift_templates_path,
        alert: @template.errors.full_messages.to_sentence
    end
  end

  def toggle
    @template.update!(active: !@template.active)
    if @template.active?
      RecurringShifts::Generator.fill_template(@template)
      notice = "Turno padrão reativado."
    else
      remove_future_occurrences(@template)
      notice = "Turno padrão pausado (turnos futuros livres removidos)."
    end
    redirect_to admin_shift_templates_path, notice: notice
  end

  def destroy
    remove_future_occurrences(@template)
    @template.destroy!
    redirect_to admin_shift_templates_path, notice: "Turno padrão removido."
  end

  private

  # Remove ocorrências futuras ainda LIVRES desse horário (não toca em reservados/passados).
  def remove_future_occurrences(template)
    current_clinic.availabilities.future.available
      .where(starts_at: template.starts_at, ends_at: template.ends_at)
      .destroy_all
  end

  def set_template
    @template = current_clinic.shift_templates.find(params[:id])
  end

  def template_params
    p = params.require(:shift_template).permit(:starts_at, :ends_at, :price)
    p[:price_cents] = price_to_cents(p.delete(:price))
    p
  end
end
