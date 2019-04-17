module Jekyll
  class KenticoPage
    def self.create(site, page_info)
      page = Jekyll::Page.allocate

      # A hack to call Jekyll::Page with custom constructor without overring
      # Jekyll-redirect-from can work only with Jekyll::Page instances
      page.define_singleton_method(:initialize) do
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
        self
      end

      return page.initialize
    end
  end
end