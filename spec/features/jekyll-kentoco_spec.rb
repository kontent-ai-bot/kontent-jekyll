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

  it 'page contains date' do
    visit('2019/12/09/default_date')
    expect(page).to have_title('Default_date')
  end

  it 'page contains tags' do
    visit('2019/12/09/default_tags')
    expect(page).to have_selector('.tags', text: 'tag1,tag2')
  end

  it 'page contains categories' do
    visit('category1/category2/2019/12/09/default_categories')
    expect(page).to have_selector('.categories', text: 'category1,category2')
  end
end

#overriden_defaults

#collections

#resolvers