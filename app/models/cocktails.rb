# This is pure business logic, since I'm dumb and decided to make models not cocktail specific
class Cocktails
  class << self
    def all_available
      Recipe.all
    end
  end
end