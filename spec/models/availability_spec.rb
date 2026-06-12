require "rails_helper"

RSpec.describe Availability, type: :model do
  subject(:availability) { build(:availability) }

  describe "associations" do
    it { is_expected.to belong_to(:clinic) }
    it { is_expected.to belong_to(:service).optional }
    it { is_expected.to belong_to(:dentist).class_name("User").optional }
    it { is_expected.to have_one(:booking) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:ends_at) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).backed_by_column_of_type(:string).with_values(available: "available", booked: "booked", cancelled: "cancelled", blocked: "blocked") }
  end

  describe "scopes" do
    let!(:future_available) { create(:availability) }
    let!(:past)             { create(:availability, :past) }
    let!(:booked)           { create(:availability, :booked) }

    it "available scope returns only available status" do
      available_ids = Availability.available.pluck(:id)
      expect(available_ids).to include(future_available.id)
      expect(available_ids).not_to include(booked.id)
    end

    it "future scope excludes past dates" do
      future_ids = Availability.future.pluck(:id)
      expect(future_ids).to include(future_available.id)
      expect(future_ids).not_to include(past.id)
    end
  end

  describe "#cancellable?" do
    context "when status is cancelled" do
      it "returns false" do
        availability = build(:availability, status: "cancelled")
        expect(availability.cancellable?).to be false
      end
    end

    context "when status is booked and slot is more than 48 hours away" do
      it "returns true" do
        av = build(:availability, :booked, date: 3.days.from_now.to_date, starts_at: "09:00", ends_at: "12:00")
        expect(av.cancellable?).to be true
      end
    end

    context "when slot is more than 48 hours away" do
      it "returns true" do
        av = build(:availability, date: 3.days.from_now.to_date, starts_at: "09:00", ends_at: "12:00")
        expect(av.cancellable?).to be true
      end
    end

    context "when slot is within 48 hours" do
      it "returns false" do
        av = build(:availability, :within_lead_time)
        expect(av.cancellable?).to be false
      end
    end
  end

  describe "PaperTrail", versioning: true do
    it "tracks changes to date but not status" do
      av = create(:availability)
      expect {
        av.update!(status: "booked")
      }.not_to change { av.versions.count }

      expect {
        av.update!(date: 5.days.from_now.to_date)
      }.to change { av.versions.count }.by(1)
    end
  end
end
