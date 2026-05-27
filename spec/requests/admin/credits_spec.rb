require "rails_helper"

RSpec.describe "Admin::Credits", type: :request do
  let(:clinic) { create(:clinic) }
  let(:owner)  { create(:user, :owner, clinic: clinic) }

  before { sign_in owner }

  describe "GET /admin/credits" do
    before do
      dentist = create(:user, :dentist, clinic: clinic)
      create(:credit, clinic: clinic, user: dentist, amount_cents: 5_000)
      create(:credit, :used, clinic: clinic, user: dentist, amount_cents: 3_000)
    end

    it "renders index" do
      get admin_credits_path
      expect(response).to have_http_status(:ok)
    end

    it "filters available" do
      get admin_credits_path, params: { status: "available" }
      expect(response).to have_http_status(:ok)
    end

    it "filters used" do
      get admin_credits_path, params: { status: "used" }
      expect(response).to have_http_status(:ok)
    end
  end
end
