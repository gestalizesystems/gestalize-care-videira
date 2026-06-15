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
  { min_slots: 2, discount_percent: 5  },
  { min_slots: 3, discount_percent: 10 },
].each do |attrs|
  DiscountRule.find_or_create_by!(clinic: clinic, min_slots: attrs[:min_slots]) do |d|
    d.discount_percent = attrs[:discount_percent]
    d.active           = true
  end
end
puts "  Desconto: 2 regras criadas"

# ── Availabilities (Aluguel de Sala) ────────────────────────────────────────
# Limpa turnos sem reserva (idempotência durante desenvolvimento)
Availability.where.not(status: "booked").destroy_all

# 3 turnos fixos: Manhã / Tarde / Noite — preço por turno
turnos = [
  { starts: "07:00", ends: "12:00", price_cents: 17000, label: "Turno Manhã"    },
  { starts: "13:00", ends: "18:00", price_cents: 17000, label: "Turno Tarde"    },
  { starts: "19:00", ends: "22:00", price_cents: 12000, label: "Turno Noite"    },
]

# Cria para os próximos 30 dias (exceto domingos)
30.times do |i|
  date = Date.tomorrow + i.days
  next if date.sunday?

  turnos.each do |t|
    next if Availability.exists?(clinic: clinic, date: date, starts_at: t[:starts])

    Availability.create!(
      clinic:      clinic,
      date:        date,
      starts_at:   t[:starts],
      ends_at:     t[:ends],
      price_cents: t[:price_cents],
      status:      "available"
    )
  end
end

puts "  Turnos: #{Availability.count} criados"

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

puts "\nSeed concluído!"
puts "  owner:   #{owner_email} | #{senha}"
puts "  dentist: dentista@videiradental.com.br | #{senha}"
