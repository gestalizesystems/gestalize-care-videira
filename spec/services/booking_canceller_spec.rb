require "rails_helper"

RSpec.describe BookingCanceller, type: :service do
  let(:clinic)       { create(:clinic) }
  let(:slot_dentist) { create(:user, :dentist, clinic: clinic) }
  let(:booker)       { create(:user, :dentist, clinic: clinic) }
  let(:group)        { create(:booking_group, clinic: clinic, dentist: booker) }
  let(:availability) { create(:availability, clinic: clinic, dentist: slot_dentist) }
  let(:booking)      { create(:booking, clinic: clinic, booking_group: group, availability: availability, dentist: booker) }

  describe ".call" do
    context "when booking is already cancelled" do
      it "returns failure without modifying anything" do
        booking.update!(status: "cancelled")
        result = BookingCanceller.call(booking: booking)
        expect(result.success?).to be false
        expect(result.error).to include("cancelada")
      end
    end

    context "when cancellation is within lead time" do
      before do
        allow(availability).to receive(:cancellable?).and_return(false)
        allow(booking).to receive(:availability).and_return(availability)
      end

      it "returns failure with lead time message" do
        result = BookingCanceller.call(booking: booking)
        expect(result.success?).to be false
        expect(result.error).to include("antecedência")
      end
    end

    context "when cancellation is valid (>48h)" do
      before do
        availability.update!(date: 3.days.from_now.to_date)
      end

      it "cancels the booking and frees the slot" do
        result = BookingCanceller.call(booking: booking)

        expect(result.success?).to be true
        expect(booking.reload.status).to eq("cancelled")
        expect(availability.reload.status).to eq("available")
      end

      it "cancels the group when all bookings are cancelled" do
        result = BookingCanceller.call(booking: booking)
        expect(group.reload.status).to eq("cancelled")
      end

      it "does not cancel group when other bookings remain active" do
        other_av = create(:availability, clinic: clinic, dentist: slot_dentist, date: 3.days.from_now.to_date, starts_at: "10:00", ends_at: "11:00")
        create(:booking, clinic: clinic, booking_group: group, availability: other_av, dentist: booker)

        BookingCanceller.call(booking: booking)
        expect(group.reload.status).to eq("pending")
      end
    end
  end
end
