require 'rails_helper'

describe "ReagentAmount" do
  include_context "basic users"

  context "tagsanity" do
    let!(:barr_hill_gin) { create(:reagent, name: 'Barr Hill Gin', user: test_user, tags: ['gin']) }
    let(:gin_shot) { create(:recipe, user: test_user) }
    let!(:the_gin) { create(:reagent_amount, user: test_user, recipe: gin_shot, tags: ['gin']) }

    it "can find across tags" do
      expect(the_gin.matching_reagents).to include(barr_hill_gin)
    end

    context "more complexity" do
      let!(:cognac_vsop) { create(:reagent, name: 'Cognac VSOP', user: test_user, tags: ['cognac', 'brandy']) }
      let!(:cheap_brandy) { create(:reagent, name: 'Cheap Brandy', user: test_user, tags: ['brandy']) }
      let(:brandy_drink) { create(:recipe, name: 'Brandy Drink', user: test_user) }
      let!(:the_brandy_in_the_drink) { create(:reagent_amount, user: test_user, recipe: brandy_drink, tags: ['brandy']) }

      it "finds both brandy options" do
        expect(the_brandy_in_the_drink.matching_reagents).to include(cognac_vsop, cheap_brandy)
      end

      context "lots more ingredients" do
        # all recipe setup
        let!(:singapore_sling) { create(:recipe, user: test_user) }
        let!(:gin) { create(:reagent_amount, user: test_user, recipe: singapore_sling, tags: ['gin', 'london_dry_gin']) }
        let!(:benedictine) { create(:reagent_amount, user: test_user, recipe: singapore_sling, tags: ['benedictine']) }
        let!(:cherry_heering) { create(:reagent_amount, user: test_user, recipe: singapore_sling, tags: ['cherry_heering']) }
        let!(:lime_juice) { create(:reagent_amount, user: test_user, recipe: singapore_sling, tags: ['lime_juice']) }
        let!(:soda_water) { create(:reagent_amount, user: test_user, recipe: singapore_sling, amount: '4', tags: ['soda_water']) }

        # existing bottles setup
        let!(:barr_hill_gin) { create(:reagent, name: 'Barr Hill Gin', user: test_user, tags: ['gin']) }
        let!(:beefeater) { create(:reagent, name: 'Beefeater Gin', user: test_user, tags: ['gin', 'london_dry_gin']) }
        let!(:cherry_heering_bottle) { create(:reagent, name: 'Cherry Heering', user: test_user, tags: ['cherry_heering']) }
        let!(:benedictine_bottle) { create(:reagent, name: 'Benedictine', user: test_user, tags: ['benedictine']) }
        let!(:lime_juice_bottle) { create(:reagent, name: 'Lime Juice', user: test_user, tags: ['lime_juice']) }
        let!(:soda_water_bottle) { create(:reagent, name: 'Soda Water', user: test_user, tags: ['soda_water']) }

        it "finds the right ingredients" do
          expect(gin.matching_reagents).to include(barr_hill_gin, beefeater)
          expect(gin.matching_reagents.count).to eq(2)
          expect(benedictine.matching_reagents).to eq([benedictine_bottle])
          expect(cherry_heering.matching_reagents).to eq([cherry_heering_bottle])
        end
      end
    end
  end
end