require 'rails_helper'

# Register directly with Capybara: the bundled Selenium predates Rails' DriverFinder integration.
Capybara.register_driver :cocktail_browser do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--window-size=1280,1000')
  driver_directories = [ENV['CHROMEWEBDRIVER'], *ENV.fetch('PATH').split(File::PATH_SEPARATOR)].compact
  driver_path = ENV['CHROMEDRIVER'] || driver_directories.map { |dir| File.join(dir, 'chromedriver') }.find { |path| File.executable?(path) }
  raise 'Install a matching ChromeDriver on PATH or set CHROMEDRIVER to its executable path (see README).' unless driver_path
  service = Selenium::WebDriver::Chrome::Service.new(path: driver_path)
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, service: service)
end

RSpec.describe 'Unified cocktail pages', type: :system do
  before do
    driven_by :cocktail_browser
    page.current_window.resize_to(1280, 1000)
    @previous_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  after do
    ActionController::Base.allow_forgery_protection = @previous_forgery_protection
    errors = page.driver.browser.logs.get(:browser).select { |entry| entry.level == 'SEVERE' && !entry.message.include?('Failed to load resource') }
    expect(errors.map(&:message)).to be_empty
  end

  let!(:cocktail) { create(:recipe, name: 'Browser Martini') }
  let!(:user) { create(:user, password: 'password123') }

  before do
    create(:reagent_category, external_id: 'gin', name: 'Gin')
    amount = create(:reagent_amount, recipe: cocktail, tags: ['gin'], amount: 1, unit: 'oz')
    cocktail << amount.convert_to_blob
    cocktail.save!
  end

  def login(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password123'
    click_button 'Log in'
    expect(page).to have_link('Sign Out')
  end

  it 'browses and scales a shared recipe as a guest, including mobile filters' do
    visit cocktails_path
    expect(page).to have_link('Browser Martini', href: cocktail_path(cocktail))
    expect(page).not_to have_select('Recipes')
    click_link 'Browser Martini'
    select '3', from: 'Servings'
    expect(page).to have_css('[data-cocktail-scale-target="amount"]', text: '3 oz')
    expect(page).not_to have_link('Edit')
    page.save_screenshot(Rails.root.join('tmp', 'cocktail-guest.png'))
    page.current_window.resize_to(390, 844)
    visit cocktails_path
    click_button 'Filters', exact: true
    fill_in 'Search term', with: 'Missing recipe'
    click_button 'Search', exact: true
    expect(page).to have_content('No cocktails found')
  end

  it 'customizes and favorites a master using the shared detail page' do
    login(user)
    visit cocktails_path
    select 'Shared recipes', from: 'Recipes'
    click_button 'Search', exact: true
    expect(page).to have_current_path(/ownership=shared/)
    click_link 'Browser Martini'
    expect(page).to have_css('h1', text: 'Browser Martini')
    click_link 'Favorite', exact: true
    expect(page).to have_link('Remove favorite')
    click_link 'Customize'
    expect(page).to have_css('#usersVersions a', text: 'Browser Martini')
    expect(page).to have_content('added to your account!')
    within('#usersVersions') { click_link 'Browser Martini' }
    expect(page).to have_link('Edit')
    expect(page).to have_content('originally copied from')
    allow(RecipeEmbeddingsService).to receive(:generate).and_return(nil)
    click_link 'Edit', exact: true
    fill_in 'Name', with: 'My Browser Martini'
    click_button 'Update Recipe'
    expect(page).to have_css('h1', text: 'My Browser Martini')
    expect(cocktail.reload.name).to eq('Browser Martini')
    click_button 'Submit for sharing'
    expect(page).to have_content('Thanks for your submission!')
  end

  it 'makes a shared drink and updates counts and personal notes through Turbo' do
    create(:reagent, user: user, name: 'Browser Gin', tags: ['gin'], current_volume_value: 5, current_volume_unit: 'oz')
    login(user)
    visit cocktail_path(cocktail)
    click_link 'Make Drink', exact: true
    expect(page).to have_css('#madeThisModal.show')
    expect(page).to have_select(nil, selected: 'Browser Gin (5.00 oz available)')
    accept_confirm { click_button 'Make this drink!' }
    expect(page).to have_css('#made_count', text: '1')
    expect(page).to have_css('#made_globally_count', text: '1')
    expect(page).not_to have_css('#madeThisModal.show')
    expect(Audit.where(user: user, recipe: cocktail).count).to eq(1)
    click_link 'Make Drink (with a twist)'
    expect(page).to have_css('#madeThisModal.show')
    expect(page).to have_content('Substitute?')
    accept_confirm { click_button 'Make this drink!' }
    expect(page).to have_css('#made_count', text: '2')
    expect(page).to have_css('#made_globally_count', text: '2')
    expect(page).to have_css('#userNotesTableBody tr', count: 2, visible: :all)
    expect(page).not_to have_css('#madeThisModal.show')
  end

  it 'lets admins publish a proposal and delete the resulting master' do
    user.update!(roles: ['admin'])
    create(:recipe, user: create(:user), name: 'Proposed cocktail', proposed_to_be_shared: true)
    login(user)
    visit cocktails_path(ownership: 'shared')
    within('#cocktailProposalsTable') { click_link 'Publish shared recipe' }
    expect(page).to have_content('Published shared recipe.')
    within('#cocktailsTable') { click_link 'Proposed cocktail' }
    expect(page).to have_css('h1', text: 'Proposed cocktail')
    accept_confirm { click_link 'Delete', exact: true }
    expect(page).to have_current_path(cocktails_path)
    expect(page).not_to have_link('Proposed cocktail')
    expect(Recipe.shared.where(name: 'Proposed cocktail')).to be_empty
  end


  it 'adds a shared recipes ingredient to the viewers shopping list' do
    list = create(:shopping_list, user: user, name: 'Weekend drinks')
    login(user)
    visit cocktail_path(cocktail)
    find('.select2-selection').click
    find('.select2-results__option', text: 'Weekend drinks').click
    click_button 'save'
    expect(page).to have_content('added to lists: Weekend drinks')
    expect(Reagent.where(shopping_list: list, user: user).sole.tags).to include('gin')
    visit cocktail_path(cocktail)
    expect(page).to have_css('.select2-selection__choice', text: 'Weekend drinks')
  end

end
