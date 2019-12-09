require 'jekyll'

class TestPage < Jekyll::Page
  def initialize(site, dir, content)
    @site = site
    @base = site.source
    @dir  = dir
    @name = 'custom_test_page.html'

    self.process(@name)
    self.data = {}
    self.content = content
  end
end

class TestCustomSiteProcessor
  def generate(site, kentico_data)
    item = kentico_data.items.find { |item| item.system.codename === 'default_data' }

    if item
      print item
      site.pages << TestPage.new(site, '.', "Test page content: #{item.elements.date.value}")
    end
  end
end
