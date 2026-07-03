puts "Seeding database..."

# ── Clinic ──────────────────────────────────────────────────────────────────
clinic = Clinic.find_or_create_by!(cnpj: "00000000000191") do |c|
  c.name  = "Videira Clinic"
  c.phone = "51999990000"
  c.email = "contato@videiradental.com.br"
end
puts "  Clínica: #{clinic.name}"

# ── Users ───────────────────────────────────────────────────────────────────
senha       = ENV.fetch("OWNER_PASSWORD", "Owner@Videira2024!")
owner_email = ENV.fetch("OWNER_EMAIL", "owner@videiradental.com.br")

owner = User.find_or_create_by!(email: owner_email) do |u|
  u.name     = "Proprietário Videira"
  u.password = senha
  u.role     = "owner"
  u.clinic   = clinic
  u.skip_confirmation!
end
puts "  Owner: #{owner.email}"

User.find_or_create_by!(email: "dentista@videiradental.com.br") do |u|
  u.name     = "Dra. Cibele Videira"
  u.password = senha
  u.role     = "dentist"
  u.clinic   = clinic
  u.skip_confirmation!
end
puts "  Dentist: dentista@videiradental.com.br"

# ── Discount rules ───────────────────────────────────────────────────────────
[
  { min_slots: 2, discount_cents: 500  },
  { min_slots: 3, discount_cents: 1000 },
].each do |attrs|
  DiscountRule.find_or_create_by!(clinic: clinic, min_slots: attrs[:min_slots]) do |d|
    d.discount_cents = attrs[:discount_cents]
    d.active         = true
  end
end
puts "  Desconto: 2 regras criadas"

# ── Serviços extra ──────────────────────────────────────────────────────────
clinic.extras.find_or_create_by!(name: "Filmaker") do |e|
  e.price_cents = 1000
end
puts "  Extras: #{clinic.extras.count}"

# ── Crédito de exemplo para a dentista demo ─────────────────────────────────
dentist = User.find_by(email: "dentista@videiradental.com.br")
if dentist && Credit.where(user: dentist, clinic: clinic).none?
  Credit.create!(
    user:         dentist,
    clinic:       clinic,
    amount_cents: 5_000,
    reason:       "Crédito promocional de boas-vindas"
  )
  puts "  Crédito demo: R$ 50,00 para #{dentist.email}"
end

# ── Turnos padrão (recorrentes) ──────────────────────────────────────────────
# Fonte ÚNICA dos turnos: os modelos (ShiftTemplate), materializados pelo
# generator. NÃO é destrutivo — não apaga turnos existentes; apenas completa a
# janela de 90 dias de forma idempotente. Tolerante a falha (nunca derruba o
# deploy). Na primeira vez (sem modelos), cria os padrões Manhã/Tarde/Noite.
begin
  if clinic.shift_templates.none?
    [
      { starts: "07:00", ends: "12:00", price_cents: 17000 },
      { starts: "13:00", ends: "18:00", price_cents: 17000 },
      { starts: "19:00", ends: "22:00", price_cents: 12000 },
    ].each do |t|
      clinic.shift_templates.create!(starts_at: t[:starts], ends_at: t[:ends], price_cents: t[:price_cents])
    end
  end
  RecurringShifts::Generator.advance(clinic)
  puts "  Turnos padrão: #{clinic.shift_templates.count} modelos | gerados até #{clinic.reload.shifts_generated_until}"
rescue => e
  puts "  [aviso] geração de turnos padrão pulada: #{e.class}: #{e.message}"
end

puts "\nSeed concluído!"
puts "  owner:   #{owner_email} | #{senha}"
puts "  dentist: dentista@videiradental.com.br | #{senha}"
