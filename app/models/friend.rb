# A dog of the address book: a dog met often during walks.
class Friend < ApplicationRecord
  belongs_to :dog
  has_many :encounters, dependent: :nullify

  validates :name, presence: true, length: { maximum: 50 }
  validates :breed, length: { maximum: 50 }
  validates :note, length: { maximum: 2000 }

  # Friends with how many times and when they were last met (computed by the database,
  # nothing is stored), most met first.
  scope :ranked, lambda {
    left_joins(:encounters)
      .select("friends.*, COUNT(encounters.id) AS encounters_count, MAX(encounters.met_at) AS last_met_at")
      .group("friends.id")
      .order(Arel.sql("COUNT(encounters.id) DESC, LOWER(friends.name)"))
  }

  # The friend with this name, ignoring upper/lower case and spaces ("sid " finds "Sid").
  def self.named(name)
    return if name.blank?

    find_by("LOWER(name) = ?", name.strip.downcase)
  end
end
