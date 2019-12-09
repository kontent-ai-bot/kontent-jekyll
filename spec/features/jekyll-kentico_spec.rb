require 'spec_helper'

# tests for defaults such as content element codename etc
describe 'default page settings' do
  it 'page contains content' do
    visit('default_content')
    expect(page).to have_content('Default content')
  end

  it 'page contains title' do
    visit('default_title')
    expect(page).to have_title('Default title')
  end

  it 'post contains date' do
    visit('2019/12/09/default_date')
    expect(page).to have_title('Default_date')
  end

  it 'post contains tags' do
    visit('2019/12/10/default_tags')
    expect(page).to have_selector('.tags', text: 'tag1,tag2')
  end

  it 'post contains categories' do
    visit('category1/category2/2019/12/11/default_categories')
    expect(page).to have_selector('.categories', text: 'category1,category2')
  end

  it 'post contains other data from content item' do
    visit('2019/12/12/default_data')
    expect(page).to have_selector('.asset-image-url', text: 'test_asset_url')
  end
end

describe 'overridden page settings' do
  it 'page contains overridden content' do
    visit('overridden_content')
    expect(page).to have_content('Overridden content')
  end

  it 'page contains overridden title' do
    visit('overridden_title')
    expect(page).to have_title('Overridden title')
  end
end

#overriden_defaults

#collections

#resolvers