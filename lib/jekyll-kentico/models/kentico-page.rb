module Jekyll
  class KenticoPage < Page
    def initialize(site, page_info)
      @site = site
      @base = site.source
      @dir = page_info.collection && "_#{page_info.collection}" || ""
      @name = page_info.filename
      @path = if site.in_theme_dir(@base) == @base
                site.in_theme_dir(@base, @dir, @name)
              else
                site.in_source_dir(@base, @dir, @name)
              end

      self.process(@name)

      self.data = page_info.front_matter
      self.content = page_info.content

      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(File.join(@dir, @name), type, key)
      end

      Jekyll::Hooks.trigger :pages, :post_init, self
    end
  end
end