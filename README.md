# Jekyll Kentico

Jekyll Kentico is utilizing Kentico Kontent, headless CMS, as a content repository and integrates it with Jekyll static site generator. You can generate posts, pages, collections and data items.

## Examples

For a working example see [this project](https://github.com/RadoslavK/kontent-jekyll-blog).

## Installation

Add this to your gem's Jekyll plugins:

```ruby
source 'https://rubygems.org'

group :jekyll_plugins do
  gem 'kontent-jekyll'
end
```

And then execute `bundle install`

## Usage

Run `bundle exec jekyll build` as you would normally build your Jekyll site.
You can also run `bundle exec jekyll serve` to run the built site.

## Configuration

To configure the extension, add the following configuration block to Jekyll's `_config.yml`:

For full configuration [see wiki](https://github.com/RadoslavK/kontent-jekyll/wiki).

```yaml
plugins:
- kontent-jekyll
kentico:
  project_id: 2dd742d6-107b-48b0-8335-6674c76c9b93
  posts:                                                      
    type: blog_post                                           
```
