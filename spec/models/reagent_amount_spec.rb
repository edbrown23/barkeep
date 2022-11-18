require 'rails_helper'

describe "ReagentAmount" do
  include_context "basic users"

  context "tagsanity" do
    let!(:gin_category) { ReagentCategory.create(name: 'Gin', external_id: 'gin') }
    let!(:barr_hill_gin) do
      Reagent.create!(
        name: 'Bar Hill Gin',
        user: test_user,
        external_id: 'bar_hill_gin',
        max_volume_unit: 'ml',
        max_volume_value: '750',
        current_volume_unit: 'ml',
        current_volume_value: '500',
        tags: ['gin']
      )
    end
    let(:gin_shot) do
      Recipe.create!(
        name: 'Gin Shot',
        category: 'cocktail',
        user: test_user
      )
    end
    let!(:the_gin) do
      ReagentAmount.create!(
        user: test_user,
        recipe: gin_shot,
        amount: '2',
        unit: 'oz',
        tags: ['gin']
      )
    end

    it "can find across tags" do
      expect(the_gin.matching_reagents).to include(barr_hill_gin)
    end

    context "more complexity" do
      let!(:cognac_vsop) do
        Reagent.create!(
          name: 'Cognac VSOP',
          external_id: 'cognac_vsop',
          user: test_user,
          current_volume_unit: 'ml',
          current_volume_value: 750,
          max_volume_unit: 'ml',
          max_volume_value: 750,
          tags: ['cognac', 'brandy']
        )
      end
      let!(:cheap_brandy) do
        Reagent.create!(
          name: 'Cheap Brandy',
          external_id: 'cheap_brandy',
          user: test_user,
          current_volume_unit: 'ml',
          current_volume_value: 750,
          max_volume_unit: 'ml',
          max_volume_value: 750,
          tags: ['brandy']
        )
      end
      let(:brandy_drink) do
        Recipe.create!(
          name: 'Brandy Drink',
          category: 'cocktail',
          user: test_user
        )
      end
      let!(:the_brandy_in_the_drink) do
        ReagentAmount.create!(
          user: test_user,
          recipe: brandy_drink,
          amount: '2',
          unit: 'oz',
          tags: ['brandy']
        )
      end

      it "finds both brandy options" do
        expect(the_brandy_in_the_drink.matching_reagents).to include(cognac_vsop, cheap_brandy)
      end

      context "lots more ingredients" do
        # all recipe setup
        let(:singapore_sling) do
          Recipe.create!(
            user: test_user,
            name: 'Singapore Sling',
            category: 'cocktail'
          )
        end
        let(:gin) do
          ReagentAmount.create!(
            user: test_user,
            recipe: singapore_sling,
            amount: '1.5',
            unit: 'oz',
            tags: ['gin', 'london_dry_gin']
          )
        end
        let(:benedictine) do
          ReagentAmount.create!(
            user: test_user,
            recipe: singapore_sling,
            amount: '1.5',
            unit: 'oz',
            tags: ['benedictine']
          )
        end
        let(:cherry_heering) do
          ReagentAmount.create!(
            user: test_user,
            recipe: singapore_sling,
            amount: '1.5',
            unit: 'oz',
            tags: ['cherry_heering']
          )
        end
        let(:lime_juice) do
          ReagentAmount.create!(
            user: test_user,
            recipe: singapore_sling,
            amount: '1.5',
            unit: 'oz',
            tags: ['lime_juice']
          )
        end
        let(:soda_water) do
          ReagentAmount.create!(
            user: test_user,
            recipe: singapore_sling,
            amount: '4',
            unit: 'oz',
            tags: ['soda_water']
          )
        end

        # existing bottles setup
        let!(:barr_hill_gin) do
          Reagent.create!(
            name: 'Barr Hill Gin',
            external_id: 'barr_hill_gin',
            user: test_user,
            current_volume_unit: 'ml',
            current_volume_value: 750,
            max_volume_unit: 'ml',
            max_volume_value: 750,
            tags: ['gin']
          )
        end
        let!(:beefeater) do
          Reagent.create!(
            name: 'Beefeater Gin',
            external_id: 'beefeater_gin',
            user: test_user,
            current_volume_unit: 'ml',
            current_volume_value: 750,
            max_volume_unit: 'ml',
            max_volume_value: 750,
            tags: ['gin', 'london_dry_gin']
          )
        end
        let!(:cherry_heering_bottle) do
          Reagent.create!(
            name: 'Cherry Heering',
            external_id: 'cherry_heering',
            user: test_user,
            current_volume_unit: 'ml',
            current_volume_value: 750,
            max_volume_unit: 'ml',
            max_volume_value: 750,
            tags: ['cherry_heering']
          )
        end
        let!(:benedictine_bottle) do
          Reagent.create!(
            name: 'Benedictine',
            external_id: 'benedictine',
            user: test_user,
            current_volume_unit: 'ml',
            current_volume_value: 750,
            max_volume_unit: 'ml',
            max_volume_value: 750,
            tags: ['benedictine']
          )
        end
        let!(:lime_juice_bottle) do
          Reagent.create!(
            name: 'Lime Juice',
            external_id: 'lime_juice',
            user: test_user,
            current_volume_unit: 'ml',
            current_volume_value: 750,
            max_volume_unit: 'ml',
            max_volume_value: 750,
            tags: ['lime_juice']
          )
        end
        let!(:soda_water_bottle) do
          Reagent.create!(
            name: 'Soda Water',
            external_id: 'soda_water',
            user: test_user,
            current_volume_unit: 'ml',
            current_volume_value: 750,
            max_volume_unit: 'ml',
            max_volume_value: 750,
            tags: ['soda_water']
          )
        end

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