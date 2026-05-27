require "rails_helper"

RSpec.describe "Booking flow", type: :system do
  let!(:clinic)  { create(:clinic) }
  let!(:dentist) { create(:user, :dentist, clinic: clinic) }
  let!(:av) do
    create(:availability,
      clinic: clinic,
      date: Date.tomorrow,
      starts_at: "08:00",
      ends_at: "12:00",
      price_cents: 17_000)
  end

  it "shows the home page with availabilities" do
    visit root_path
    expect(page).to have_content(av.label)
    expect(page).to have_content("R$ 170,00")
  end

  it "adds an availability to the cart" do
    visit root_path
    expect {
      click_button "R$ 170,00", match: :first
    }.to change { page.has_content?("Toque para remover") }.from(false).to(true)
  end

  context "as a signed in dentist" do
    before { sign_in dentist }

    it "completes a reservation with sandbox Pix" do
      ENV["MERCADOPAGO_ACCESS_TOKEN"] = "TEST-mock-token"

      visit root_path
      click_button "R$ 170,00", match: :first

      click_link "Confirmar →", match: :first
      expect(page).to have_content("Confirmar reserva")

      click_button "Confirmar e gerar Pix →"
      expect(page).to have_content("Pagamento via Pix")
      expect(page).to have_content("Tempo restante")
    ensure
      ENV.delete("MERCADOPAGO_ACCESS_TOKEN")
    end
  end
end
