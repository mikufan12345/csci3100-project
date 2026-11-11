class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles (users.role, integer)
  PLAYTESTER   = 0
  ARBITER      = 1
  STUDIO_ADMIN = 2

  ROLES = { playtester: PLAYTESTER, arbiter: ARBITER, studio_admin: STUDIO_ADMIN }.freeze

  belongs_to :studio
  has_many :playtest_sessions, dependent: :destroy

  # Virtual attribute filled on the signup form (membership rule A):
  #  - matches an existing studio (case-insensitive) -> join it as playtester
  #  - is new                                         -> found it as studio_admin
  attr_accessor :studio_name

  validates :role, inclusion: { in: ROLES.values }, allow_nil: true

  before_validation(on: :create) { assign_studio_on_signup }

  def role_name
    ROLES.keys.find { |_, v| v == role }&.to_s
  end

  private

  def assign_studio_on_signup
    return if studio_id?

    name = studio_name.to_s.strip
    if name.blank?
      errors.add(:studio_name, "is required to join or create a studio")
      return
    end

    existing = Studio.where("LOWER(name) = ?", name.downcase).first
    if existing
      self.studio = existing
      self.role = User::PLAYTESTER # no self-promotion into existing studios
    else
      self.studio = Studio.create!(name: name)
      self.role = User::STUDIO_ADMIN # first user founds the studio
    end
  end
end