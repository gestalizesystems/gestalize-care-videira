require "rails_helper"

RSpec.describe "Admin::Services", type: :request do
  let(:clinic) { create(:clinic) }
  let(:owner)  { create(:user, :owner, clinic: clinic) }
  let(:other_dentist) { create(:user, :dentist, clinic: clinic) }

  context "as owner" do
    before { sign_in owner }

    describe "GET /admin/services" do
      it "renders the index" do
        get admin_services_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/services" do
      it "creates a service" do
        expect {
          post admin_services_path, params: { service: { name: "Limpeza", duration_minutes: 30, price: "120,50" } }
        }.to change(Service, :count).by(1)
        created = Service.last
        expect(created.price_cents).to eq(12_050)
      end

      it "renders new on invalid params" do
        post admin_services_path, params: { service: { name: "", duration_minutes: 0 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH /admin/services/:id" do
      let!(:service) { create(:service, clinic: clinic) }

      it "updates the service" do
        patch admin_service_path(service), params: { service: { name: "Novo nome" } }
        expect(service.reload.name).to eq("Novo nome")
      end
    end

    describe "DELETE /admin/services/:id" do
      let!(:service) { create(:service, clinic: clinic) }

      it "deactivates instead of destroying" do
        delete admin_service_path(service)
        expect(service.reload.active?).to be false
      end
    end
  end

  context "as non-owner" do
    before { sign_in other_dentist }

    it "is blocked from index" do
      get admin_services_path
      expect(response).to redirect_to(root_path)
    end
  end
end
