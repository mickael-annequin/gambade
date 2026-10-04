module DogsHelper
  # "Border Collie · 1 an et 8 mois", "Border Collie · 4 ans", "8 mois"...
  def dog_details(dog)
    [ dog.breed.presence, age_text(dog.age_in_months) ].compact.join(" · ")
  end

  private

  def age_text(months)
    return if months.nil?

    years = pluralize(months / 12, "an", plural: "ans") if months >= 12
    rest = "#{months % 12} mois" if (months % 12).positive? || months.zero?
    [ years, rest ].compact.join(" et ")
  end
end
