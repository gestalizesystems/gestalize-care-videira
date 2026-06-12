require "rails_helper"

RSpec.describe "Admin::Clinics", type: :request do
  let(:clinic) { create(:clinic) }
  let(:owner)  { create(:user, :owner, clinic: clinic) }

  before { sign_in owner }

  describe "GET /admin/clinics/:id" do
    it "renders show" do
      get admin_clinic_path(clinic)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/clinics/:id" do
    it "updates the clinic" do
      patch admin_clinic_path(clinic), params: { clinic: { name: "Novo Nome" } }
      expect(clinic.reload.name).to eq("Novo Nome")
    end
  end
end
