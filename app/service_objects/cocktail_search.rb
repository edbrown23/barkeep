class CocktailSearch
  attr_reader :ownership, :availability, :tags

  def initialize(viewer, params)
    @viewer = viewer
    @params = params
    @tags = Array.wrap(params[:search_tags]).reject(&:blank?)
    @ownership = normalized_ownership
  end

  def results
    @results ||= begin
      scope = Recipe.cocktails.visible_to(@viewer).where.not(source: 'drink_builder')
      scope = scope.where(user_id: @viewer.id) if ownership == 'mine'
      scope = scope.shared if ownership == 'shared'
      scope = scope.none if ownership == 'none'
      if @viewer && @params[:family_ids].present?
        family_ids = visible_families.where(id: @params[:family_ids]).select(:id)
        scope = scope.where(id: CocktailFamilyJoiner.where(cocktail_family_id: family_ids).select(:recipe_id))
      end
      scope = scope.where('name ILIKE ?', "%#{@params[:search_term]}%") if @params[:search_term].present?
      scope = scope.by_tag(*tags) if tags.any?
      if @viewer
        @availability = CocktailAvailabilityService.new(scope, @viewer)
        scope = scope.where(id: availability.makeable_ids) if @params[:makeable] == 'on'
      end
      scope
    end
  end

  def cocktails
    results.reorder(:name, :id).page(@params[:page])
  end

  def families
    return CocktailFamily.none unless @viewer

    visible_families.where(id: CocktailFamilyJoiner.where(recipe_id: results.reselect(:id)).select(:cocktail_family_id)).order(:name)
  end

  def reagent_categories
    ReagentCategory.where(external_id: results.flat_map(&:tags)).order(:name)
  end

  def facets
    return {} unless results.exists?

    # ts_stat accepts SQL as a string. Quote the complete query as a value;
    # dollar quoting breaks when a user's search itself contains $$.
    connection = ActiveRecord::Base.connection
    query = results.reselect(:searchable).reorder(nil).to_sql
    connection.execute("SELECT word, ndoc FROM ts_stat(#{connection.quote(query)}) ORDER BY ndoc DESC, word").entries.index_by { |facet| facet['word'] }
  end

  private

  def visible_families
    CocktailFamily.where(user_id: [nil, @viewer.id])
  end

  def normalized_ownership
    return 'shared' unless @viewer
    return @params[:ownership] if %w[all mine shared].include?(@params[:ownership])
    return 'all' if @params[:ownership].present?

    mine = @params[:user_recipes_only] == 'on'
    shared = @params[:shared_recipes_only] == 'on'
    return 'none' if mine && shared
    return 'mine' if mine
    return 'shared' if shared

    'all'
  end
end
