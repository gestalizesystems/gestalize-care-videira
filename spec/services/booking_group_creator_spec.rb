require "rails_helper"

RSpec.describe BookingGroupCreator, type: :service do
  let(:clinic)   { create(:clinic) }
  let(:patient)  { create(:user, :dentist, clinic: clinic) }
  let(:service)  { create(:service, clinic: clinic, price_cents: 15_000) }
  let(:av1)      { create(:availability, clinic: clinic, service: service) }
  let(:av2)      { create(:availability, clinic: clinic, service: service) }

  let(:pix_result) do
    ApplicationService::Result.new(
      success: true,
      value: {
        gateway_id: "SANDBOX_1",
        pix_qr_code: "00020101...",
        pix_qr_url: "",
        expires_at: 30.minutes.from_now
      },
      error: nil
    )
  end

  before do
    allow(MercadoPago::PixCreator).to receive(:call).and_return(pix_result)
  end

  describe ".call" do
    context "with empty availability_ids" do
      it "returns failure" do
        result = BookingGroupCreator.call(user: patient, availability_ids: [])
        expect(result.success?).to be false
        expect(result.error).to include("Selecione")
      end
    end

    context "with valid available slots" do
      it "creates a booking group, bookings, and payment" do
        result = BookingGroupCreator.call(user: patient, availability_ids: [av1.id, av2.id])

        expect(result.success?).to be true
        group = result.value
        expect(group).to be_a(BookingGroup)
        expect(group.bookings.count).to eq(2)
        expect(group.payment).to be_present
        expect(group.payment.gateway_id).to eq("SANDBOX_1")
      end

      it "marks availabilities as booked" do
        BookingGroupCreator.call(user: patient, availability_ids: [av1.id])
        expect(av1.reload.status).to eq("booked")
      end

      it "calls MercadoPago::PixCreator" do
        BookingGroupCreator.call(user: patient, availability_ids: [av1.id])
        expect(MercadoPago::PixCreator).to have_received(:call)
      end
    end

    context "when a slot is no longer available" do
      before { av1.update!(status: "booked") }

      it "returns failure and rolls back" do
        expect {
          result = BookingGroupCreator.call(user: patient, availability_ids: [av1.id])
          expect(result.success?).to be false
          expect(result.error).to include("disponíveis")
        }.not_to change(BookingGroup, :count)
      end
    end

    context "when MercadoPago returns an error" do
      let(:failed_pix) { ApplicationService::Result.new(success: false, value: nil, error: "MP error") }

      before { allow(MercadoPago::PixCreator).to receive(:call).and_return(failed_pix) }

      it "returns failure and rolls back the transaction" do
        expect {
          result = BookingGroupCreator.call(user: patient, availability_ids: [av1.id])
          expect(result.success?).to be false
        }.not_to change(Payment, :count)

        expect(av1.reload.status).to eq("available")
      end
    end

    context "with a discount rule applicable" do
      before { create(:discount_rule, clinic: clinic, min_slots: 2, discount_percent: 10) }

      it "applies discount to total" do
        result = BookingGroupCreator.call(user: patient, availability_ids: [av1.id, av2.id])
        group = result.value
        expect(group.discount_cents).to eq(3_000)
        expect(group.total_cents).to eq(27_000)
      end
    end
  end
end
