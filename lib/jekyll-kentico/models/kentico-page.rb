module Jekyll
  class KenticoPage < Page
    def initialize(site, page_info)
      @site = site
      @base = site.source
      @dir = page_info.collection
      @name = page_info.filename

      self.process(@name)

      self.data = page_info.data
      self.content = page_info.content
    end
  end
end