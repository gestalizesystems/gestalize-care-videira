require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "associations" do
    it { is_expected.to belong_to(:clinic).optional }
    it { is_expected.to have_many(:availabilities).with_foreign_key(:dentist_id) }
    it { is_expected.to have_many(:booking_groups).with_foreign_key(:dentist_id) }
    it { is_expected.to have_many(:bookings).with_foreign_key(:dentist_id) }

    it "has an avatar attachment" do
      expect(User.new).to respond_to(:avatar)
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    it "accepts nil cpf" do
      expect(build(:user, cpf: nil)).to be_valid
    end

    it "rejects cpf with wrong format" do
      user = build(:user, cpf: "123")
      expect(user).not_to be_valid
      expect(user.errors[:cpf]).to be_present
    end

    it "accepts cpf with 11 digits" do
      expect(build(:user, cpf: "12345678901")).to be_valid
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).backed_by_column_of_type(:string).with_values(owner: "owner", dentist: "dentist") }
  end

  describe "scopes" do
    let!(:dentist) { create(:user, :dentist) }
    let!(:owner)   { create(:user, :owner) }

    it ".dentists returns only dentists" do
      expect(User.dentists).to include(dentist)
      expect(User.dentists).not_to include(owner)
    end
  end

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "google_123",
        info: { email: "google@example.com", name: "Google User" }
      )
    end

    it "creates a new user" do
      expect { User.from_omniauth(auth) }.to change(User, :count).by(1)
    end

    it "returns nil when email is blank" do
      auth.info.email = ""
      expect(User.from_omniauth(auth)).to be_nil
    end

    it "finds existing user on second call" do
      User.from_omniauth(auth)
      expect { User.from_omniauth(auth) }.not_to change(User, :count)
    end
  end

  describe "paper_trail", versioning: true do
    it "tracks changes" do
      user = create(:user)
      expect { user.update!(name: "Novo Nome") }.to change { user.versions.count }.by(1)
    end
  end
end
