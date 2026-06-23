module RecurringShifts
  # Materializa os turnos recorrentes (ShiftTemplate) em Availabilities concretas.
  class Generator
    HORIZON_DAYS = 90

    # Geração (job diário + backfill): garante os turnos para toda a janela de
    # 90 dias. É idempotente (pula os que já existem) e auto-corretivo — se algum
    # dia ficou sem turno, ele preenche. Para pular um dia específico (feriado),
    # o admin deve BLOQUEAR o turno (toggle) em vez de excluir: bloqueado conta
    # como existente e não é recriado.
    def self.advance(clinic)
      templates = clinic.shift_templates.active.to_a
      return if templates.empty?

      target_end = Date.current + HORIZON_DAYS
      # Chave pelo intervalo completo (início + fim): assim uma Diária (07–18)
      # não é confundida com a Manhã (07–12), que tem o mesmo horário de início.
      existing = clinic.availabilities.where(date: Date.current..target_end)
                       .pluck(:date, :starts_at, :ends_at)
                       .map { |d, s, e| [d, s.strftime("%H:%M"), e.strftime("%H:%M")] }.to_set

      (Date.current..target_end).each do |date|
        templates.each do |t|
          next if existing.include?([date, t.starts_at.strftime("%H:%M"), t.ends_at.strftime("%H:%M")])
          create_availability(clinic, t, date)
        end
      end

      clinic.update_column(:shifts_generated_until, target_end)
    end

    # Preenche UM template em toda a janela já gerada (ao criar/reativar um modelo),
    # sem mexer nos outros turnos (não reaparecem os que o admin excluiu).
    def self.fill_template(template)
      clinic     = template.clinic
      target_end = [clinic.shifts_generated_until || Date.current, Date.current + HORIZON_DAYS].max
      (Date.current..target_end).each { |date| create_availability(clinic, template, date) }
    end

    def self.create_availability(clinic, template, date)
      # Dedup pelo intervalo completo: uma Diária (07–18) e a Manhã (07–12)
      # compartilham o starts_at mas são turnos distintos.
      return if clinic.availabilities
                       .where(date: date, starts_at: template.starts_at, ends_at: template.ends_at)
                       .exists?

      clinic.availabilities.create(
        date:        date,
        starts_at:   template.starts_at,
        ends_at:     template.ends_at,
        price_cents: template.price_cents,
        status:      "available"
      )
    rescue ActiveRecord::RecordNotUnique
      # corrida — outro processo já criou o mesmo turno
    rescue => e
      # nunca deixa um dia/turno problemático abortar a geração dos demais
      Rails.logger.warn("[RecurringShifts] falha ao gerar turno #{date} #{template.starts_at}: #{e.class}: #{e.message}")
    end
  end
end
