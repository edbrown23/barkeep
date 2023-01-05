class ReagentResolver
  def initialize(current_user)
    @tags = []
    @reagent_by_tag = {}
    @current_user = current_user
  end

  def register_tags(tags)
    @tags.concat(Array.wrap(tags))
  end

  def reset
    @tags = []
  end
  
  def reagents(tag)
    resolve
    @reagent_by_tag[tag]
  end

  private

  def resolve
    return if @tags.empty?

    Reagent.for_user(@current_user).with_tags(@tags).each do |reagent|
      reagent.tags.each do |tag|
        @reagent_by_tag[tag] ||= []
        @reagent_by_tag[tag] << reagent
      end
    end
    reset
  end
end