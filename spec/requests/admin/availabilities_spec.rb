require "rails_helper"

RSpec.describe "Admin::Availabilities", type: :request do
  let(:clinic) { create(:clinic) }
  let(:owner)  { create(:user, :owner, clinic: clinic) }

  before { sign_in owner }

  describe "GET /admin/availabilities" do
    it "renders index" do
      get admin_availabilities_path
      expect(response).to have_http_status(:ok)
    end

    it "renders with date filter" do
      get admin_availabilities_path, params: { date: Date.tomorrow.to_s }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/availabilities" do
    let(:params) do
      {
        availability: {
          date:      Date.tomorrow.to_s,
          starts_at: "08:00",
          ends_at:   "12:00",
          price:     "170,00"
        }
      }
    end

    it "creates an availability" do
      expect { post admin_availabilities_path, params: params }.to change(Availability, :count).by(1)
      av = Availability.last
      expect(av.price_cents).to eq(17_000)
    end
  end

  describe "PATCH /admin/availabilities/:id/toggle" do
    let!(:availability) { create(:availability, clinic: clinic, status: "available") }

    it "blocks an available slot" do
      patch toggle_admin_availability_path(availability)
      expect(availability.reload.blocked?).to be true
    end

    it "rejects toggling booked slot" do
      availability.update!(status: "booked")
      patch toggle_admin_availability_path(availability)
      expect(availability.reload.status).to eq("booked")
    end
  end

  describe "DELETE /admin/availabilities/:id" do
    let!(:availability) { create(:availability, clinic: clinic) }

    it "destroys the availability" do
      expect { delete admin_availability_path(availability) }.to change(Availability, :count).by(-1)
    end

    it "refuses to delete booked slots" do
      availability.update!(status: "booked")
      expect { delete admin_availability_path(availability) }.not_to change(Availability, :count)
    end
  end
end
