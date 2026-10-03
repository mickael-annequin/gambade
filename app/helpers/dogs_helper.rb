module DogsHelper
  # "Border Collie · 4 ans", "Border Collie", "moins d'un an"...
  def dog_details(dog)
    [ dog.breed.presence, age_text(dog.age) ].compact.join(" · ")
  end

  private

  def age_text(age)
    return if age.nil?
    return "moins d'un an" if age.zero?

    pluralize(age, "an", plural: "ans")
  end
end
