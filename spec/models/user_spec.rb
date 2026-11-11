require "rails_helper"

RSpec.describe User, type: :model do
  describe "signup (membership rule A)" do
    it "founds a new studio as its first admin" do
      user = User.new(email: "founder@example.com", password: "hunter22",
                      studio_name: "Fresh Tabletop Co.")
      expect(user).to be_valid
      user.save!
      expect(user.role).to eq(User::STUDIO_ADMIN)
      expect(user.studio.name).to eq("Fresh Tabletop Co.")
    end

    it "joins an existing studio as a playtester (case-insensitive)" do
      Studio.create!(name: "Neon Dice Co.")
      user = User.new(email: "late@example.com", password: "hunter22",
                      studio_name: "neon dice co.")
      user.save!
      expect(user.role).to eq(User::PLAYTESTER)
      expect(user.studio.name).to eq("Neon Dice Co.")
    end

    it "requires a studio name" do
      user = User.new(email: "nameless@example.com", password: "hunter22", studio_name: "")
      expect(user).not_to be_valid
      expect(user.errors[:studio_name]).not_to be_empty
    end
  end

  describe "roles" do
    it "accepts only known roles" do
      user = User.new(email: "r@example.com", password: "hunter22",
                      studio_name: "Role Studio")
      user.role = User::ARBITER
      expect(user).to be_valid
      user.role = 99
      expect(user).not_to be_valid
    end
  end
end