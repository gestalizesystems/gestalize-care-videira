require "rails_helper"

RSpec.describe "Admin::Payments", type: :request do
  let(:clinic)  { create(:clinic) }
  let(:owner)   { create(:user, :owner, clinic: clinic) }
  let(:dentist) { create(:user, :dentist, clinic: clinic) }
  let(:group)   { create(:booking_group, clinic: clinic, dentist: dentist) }
  let(:payment) { create(:payment, clinic: clinic, booking_group: group) }

  describe "GET /admin/payments" do
    context "as owner" do
      before { sign_in owner }

      it "returns 200" do
        get admin_payments_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "as dentist" do
      before { sign_in dentist }

      it "redirects (access denied)" do
        get admin_payments_path
        expect(response).not_to have_http_status(:ok)
      end
    end

    context "unauthenticated" do
      it "redirects to login" do
        get admin_payments_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/payments/:id" do
    before { sign_in owner }

    it "returns 200 for an existing payment" do
      get admin_payment_path(payment)
      expect(response).to have_http_status(:ok)
    end
  end
end
