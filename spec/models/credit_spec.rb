require "rails_helper"

RSpec.describe Credit, type: :model do
  subject { build(:credit) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:clinic) }
    it { is_expected.to belong_to(:source_booking_group).class_name("BookingGroup").optional }
    it { is_expected.to belong_to(:used_on_booking_group).class_name("BookingGroup").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_numericality_of(:amount_cents).is_greater_than(0) }
  end

  describe "scopes" do
    let(:clinic) { create(:clinic) }
    let(:user)   { create(:user, :dentist, clinic: clinic) }
    let!(:avail) { create(:credit, user: user, clinic: clinic) }
    let!(:done)  { create(:credit, :used, user: user, clinic: clinic) }

    it ".available returns only unused" do
      expect(Credit.available).to contain_exactly(avail)
    end

    it ".used returns only used" do
      expect(Credit.used).to contain_exactly(done)
    end
  end

  describe ".balance_for" do
    let(:clinic) { create(:clinic) }
    let(:user)   { create(:user, :dentist, clinic: clinic) }

    it "sums available credits" do
      create(:credit, user: user, clinic: clinic, amount_cents: 5_000)
      create(:credit, user: user, clinic: clinic, amount_cents: 3_000)
      create(:credit, :used, user: user, clinic: clinic, amount_cents: 9_999)

      expect(Credit.balance_for(user: user, clinic: clinic)).to eq(8_000)
    end

    it "returns 0 when no credits" do
      expect(Credit.balance_for(user: user, clinic: clinic)).to eq(0)
    end
  end

  describe "#available?" do
    it "is true when used_at is nil" do
      expect(build(:credit, used_at: nil)).to be_available
    end

    it "is false when used_at is set" do
      expect(build(:credit, used_at: Time.current)).not_to be_available
    end
  end
end
