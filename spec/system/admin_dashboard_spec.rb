require "rails_helper"

RSpec.describe "Admin dashboard", type: :system do
  let!(:clinic) { create(:clinic) }
  let!(:owner)  { create(:user, :owner, clinic: clinic) }

  before { sign_in owner }

  it "shows the dashboard metrics" do
    visit admin_root_path
    expect(page).to have_content("Dashboard")
    expect(page).to have_content("Agendamentos hoje")
    expect(page).to have_content("Pag. pendentes")
    expect(page).to have_content("Receita do mês")
  end

  it "navigates to Turnos" do
    visit admin_root_path
    click_link "Turnos", match: :first
    expect(page).to have_current_path(admin_availabilities_path)
  end

  it "navigates to Clientes" do
    visit admin_root_path
    click_link "Clientes", match: :first
    expect(page).to have_current_path(admin_users_path)
  end
end
