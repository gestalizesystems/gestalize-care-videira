require "rails_helper"

RSpec.describe "Admin::Bookings", type: :request do
  let(:clinic)  { create(:clinic) }
  let(:owner)   { create(:user, :owner, clinic: clinic) }
  let(:dentist) { create(:user, :dentist, clinic: clinic) }
  let!(:group)  { create(:booking_group, :with_bookings, clinic: clinic, dentist: dentist) }

  before { sign_in owner }

  describe "GET /admin/bookings" do
    it "renders index" do
      get admin_bookings_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      get admin_bookings_path, params: { status: "pending" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/bookings/:id" do
    it "renders show" do
      get admin_booking_path(group)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/bookings/:id/cancelar" do
    it "cancels the group" do
      patch cancelar_admin_booking_path(group)
      expect(group.reload.cancelled?).to be true
    end

    it "blocks double cancellation" do
      group.cancel!
      patch cancelar_admin_booking_path(group)
      expect(flash[:alert]).to be_present
    end
  end
end
