require "rails_helper"

RSpec.describe PaymentConfirmer, type: :service do
  let(:group)   { create(:booking_group) }
  let!(:payment) { create(:payment, booking_group: group, clinic: group.clinic) }

  before { allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to) }

  describe ".call" do
    context "when booking group does not exist" do
      it "returns success with :not_found" do
        result = PaymentConfirmer.call(external_reference: "non-existent-id")
        expect(result.success?).to be true
        expect(result.value).to eq(:not_found)
      end
    end

    context "when group is already confirmed (idempotent)" do
      it "returns success without re-processing" do
        group.update!(status: "confirmed")
        result = PaymentConfirmer.call(external_reference: group.id)
        expect(result.success?).to be true
        expect(result.value).to eq(:already_processed)
      end
    end

    context "when group is pending" do
      let!(:booking) { create(:booking, booking_group: group, clinic: group.clinic) }

      it "confirms the group, bookings, and payment" do
        result = PaymentConfirmer.call(external_reference: group.id)

        expect(result.success?).to be true
        expect(group.reload.status).to eq("confirmed")
        expect(booking.reload.status).to eq("confirmed")
        expect(payment.reload.status).to eq("paid")
        expect(payment.reload.paid_at).to be_present
      end

      it "broadcasts a Turbo Stream update" do
        PaymentConfirmer.call(external_reference: group.id)
        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to)
          .with("payment_#{payment.id}", hash_including(target: "payment_status"))
      end
    end
  end
end
