require "rails_helper"

RSpec.describe BookingGroup, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:clinic) }
    it { is_expected.to belong_to(:dentist).class_name("User") }
    it { is_expected.to belong_to(:discount_rule).optional }
    it { is_expected.to have_many(:bookings).dependent(:destroy) }
    it { is_expected.to have_one(:payment).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:booking_group) }
    it { is_expected.to validate_presence_of(:subtotal_cents) }
    it { is_expected.to validate_presence_of(:total_cents) }
    it { is_expected.to validate_numericality_of(:subtotal_cents).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:discount_cents).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).backed_by_column_of_type(:string).with_values(pending: "pending", confirmed: "confirmed", cancelled: "cancelled", expired: "expired") }
  end

  describe "#expire!" do
    context "when status is pending" do
      it "sets status to expired and frees availabilities" do
        group = create(:booking_group, :with_bookings)
        group.expire!

        expect(group.reload.status).to eq("expired")
        group.bookings.each do |b|
          expect(b.reload.status).to eq("cancelled")
          expect(b.availability.reload.status).to eq("available")
        end
      end
    end

    context "when status is not pending" do
      it "does nothing" do
        group = create(:booking_group, :confirmed)
        expect { group.expire! }.not_to change { group.reload.status }
      end
    end
  end

  describe "#cancel!" do
    context "when status is pending" do
      it "cancels the group and frees availabilities" do
        group = create(:booking_group, :with_bookings)
        group.cancel!

        expect(group.reload.status).to eq("cancelled")
        group.bookings.each { |b| expect(b.availability.reload.status).to eq("available") }
      end
    end

    context "when already cancelled" do
      it "is idempotent and does not raise" do
        group = create(:booking_group, :cancelled)
        expect { group.cancel! }.not_to raise_error
        expect(group.reload.status).to eq("cancelled")
      end
    end
  end
end
