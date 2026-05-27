require "rails_helper"

RSpec.describe CreditIssuer, type: :service do
  let(:clinic)  { create(:clinic) }
  let(:dentist) { create(:user, :dentist, clinic: clinic) }
  let(:group)   { create(:booking_group, clinic: clinic, dentist: dentist) }

  context "when payment is paid" do
    let!(:payment) { create(:payment, clinic: clinic, booking_group: group, status: "paid", amount_cents: 12_000) }

    it "creates a credit equal to payment amount" do
      result = CreditIssuer.call(booking_group: group)
      expect(result.success?).to be true
      credit = result.value
      expect(credit).to be_a(Credit)
      expect(credit.amount_cents).to eq(12_000)
      expect(credit.user).to eq(dentist)
      expect(credit.source_booking_group).to eq(group)
    end

    it "uses provided reason" do
      result = CreditIssuer.call(booking_group: group, reason: "Custom reason")
      expect(result.value.reason).to eq("Custom reason")
    end

    it "falls back to default reason" do
      result = CreditIssuer.call(booking_group: group)
      expect(result.value.reason).to include("Cancelamento")
    end
  end

  context "when payment is pending" do
    let!(:payment) { create(:payment, clinic: clinic, booking_group: group, status: "pending") }

    it "does not create a credit" do
      expect {
        result = CreditIssuer.call(booking_group: group)
        expect(result.success?).to be true
        expect(result.value).to be_nil
      }.not_to change(Credit, :count)
    end
  end

  context "when group has no payment" do
    it "does not create a credit" do
      expect {
        CreditIssuer.call(booking_group: group)
      }.not_to change(Credit, :count)
    end
  end

  context "when booking_group is nil" do
    it "returns failure" do
      result = CreditIssuer.call(booking_group: nil)
      expect(result.failure?).to be true
    end
  end
end
