# Jekyll Kentico

Jekyll Kentico is utilizing Kentico Cloud, headless CMS, as a content repository and integrates it with Jekyll static site generator. You can generate posts, pages, collections and data items.

## Examples

For a working example see [this project](https://github.com/RadoslavK/jekyll-blog).

## Installation

Add this to your gem's Jekyll plugins:

```ruby
source 'https://rubygems.org'

group :jekyll_plugins do
  gem 'jekyll-kentico'
end
```

And then execute `bundle install`

## Usage

Run `bundle exec jekyll build` as you would normally build your Jekyll site.
You can also run `bundle exec jekyll serve` to run the built site.

## Configuration

To configure the extension, add the following configuration block to Jekyll's `_config.yml`:

```yaml
plugins:
- jekyll-kentico
kentico:
  project_id: 2dd742d6-107b-48b0-8335-6674c76c9b93            # Required
  secure_key: 75084b6e-dd0f-4b5d-a2da-66f2a248cec5            # Required if secure toggle is on
  front_matter_resolver: FrontMatterResolver
  content_resolver: ContentResolver
  filename_resolver: FilenameResolver
  data_resolver: DataResolver
  content_link_resolver: ContentLinkResolver
  inline_content_item_resolver: InlineContentItemResolver
  max_linked_items_depth: 0                                   # Defaults to 1
  default_layout: default                         
  languages:                                                  # Defaults to [nil]
    - en-US
    - fr-FR
  posts:                                                      
    type: blog_post
    date: published                                           # Defaults to 'date'
    layout: post
    content: long_description                                 # Defaults to 'content'
    title: post_title                                         # Defaults to 'title'
    tags: post_tags
    categories: post_categories
  pages:                                                      # The same _title_, _content_ defaults as posts                   
    home:
    page:
    author:
      title: name
      layout: author
      collection: authors
  data:
    author: authors                                          # Defaults to used content type codename
  taxonomies:                                                
    - site                                                    
```

### Secure variables

You can use environment variables to hide your secrets from a public config.
To do so, you need to prefix the project id and secure key values with `ENV_`.
For example the `PROJECT_ID` and `DELIVERY_API_KEY` variables will be used. 

```yaml
kentico:
  project_id: ENV_PROJECT_ID
  secure_key: ENV_DELIVERY_API_KEY
```
### Config parameters

Parameter                       | Description
----------                      | ------------
project_id                      | Kentico Cloud project id
secure_key                      | Delivery secure key for the project
front_matter_resolver           | Class name of the page front matter resolver, see Resolvers section
content_resolver                | Class name of the page content resolver, see Resolvers section
filename_resolver               | Class name of the page filename resolver, see Resolvers section
data_resolver                   | Class name of the data items resolver, see Resolvers section
content_link_resolver           | Class name of rich text content link resolver, see Resolvers section
inline_content_item_resolver    | Class name of rich text inline content item resolver, see Resolvers section
max_linked_items_depth          | Maximum depth of resolved linked items
default_layout                  | Default layout filename without the extension used for all content
languages                       | Array of languages to retrieve, if not specified then Kentico Cloud project default language will be loaded
posts                           | See _Posts_ config
pages                           | Hash where keys are content type names values are specific page configs, see _Page config_
data                            | Hash where keys are content type names and values are accessor names in _site.data_ object.
taxonomies                      | Array of taxonomy group codenames to retrieve

## Posts

### Config parameters

Parameter                       | Description
----------                      | ------------
type                            | Content type codename
date                            | Content item element codename used for post date. Defaults to `date`. Expects DateTime element
layout                          | Layout filename without the extension
content                         | Content item element codename used for post content. Defaults to `content`. Expects Text/Rich Text element
title                           | Content item element codename used for post title. Defaults to `title`. Expects Text element
tags                            | Content item element codename used for post tags
categories                      | Content item element codename used for post categories

All generated posts will be merged with content from the _posts directory.

To generate posts you need to specify posts part of your config and the post's content type.

Layout, date, title, tags, categories and content are optional parameters but the content item of specified type needs to have element with codenames matching the defaults to generate the posts correctly.

The generated file will be in a typical Jekyll post format with content being generated automatically. If you use Rich Text element for your content and use content item links or content components(inline content items) then you need to define your resolvers. See resolvers section below.

The initial front matter will have the values of date, layout, title, tags, categories and item and then processed like a regular Jekyll post file. For item value see content item model below.

Filename will be in a standar format of `year-month-day-slug.html`. The slug is taken from URLSlug element. If no url slug is found then content item codename will be used.

You can also override the generated filename, whole content and front matter with a custom resolver as well.

## Pages

### Page config parameters for particular content type

Parameter                       | Description
----------                      | ------------
layout                          | Layout filename without the extension
content                         | Content item element codename used for post content
title                           | Content item element codename used for post title
collection                      | Collection name for the page

All generated pages will be merged with all other Jekyll pages inside your site directory.

To generate pages you need to specify pages part of your config and the post's content type.

Layout, title and content are optional parameters but the content item of specified type needs to have element with codenames matching the defaults to generate the pages correctly.

The generated file will be in a typical Jekyll page format with content being generated automatically. If you use Rich Text element for your content and use content item links or content components(inline content items) then you need to define your resolvers. See resolvers section below.

The initial front matter will have the values of layout, title and item and then processed like a regular Jekyll page file. For item value see content item model below.

Filename will be in a format of `slug.html`. The slug is taken from URLSlug element. If no url slug is found then content item codename will be used.

You can also override the generated filename, whole content and front matter with a custom resolver as well.

If you want to add your pages to a collection then specify a collection name in the page config.

## Layouts

Jekyll posts and pages do not have any default layouts. You can specify a default layout
for all content. The layout name should correspond to your layout's filename without the
extension. Each content type can be associated with different layout.

## Data items

You can generate data items to be accessible through the `site.data`. Add the data part to your
config and all content types will be added to accessor based on their content types codename.
You can override the accessor's name with a value associated with the content type codename key.
Then you can accesss the items at `site.data.accessor_name`.

You can also specifiy a data resolver to map the content items into custom format. See resolvers below.

## Taxonomies

To retrieve taxonomies add taxonomies part to the config. Taxonomies will be stored in `site.data.taxonomies`.
You can access specific taxonomy group data by the taxonomy group codename eg `site.data.taxonomies.sitemap`

[Taxonomy group model](https://developer.kenticocloud.com/reference#list-taxonomy-groups)

## Content item model

By default you can access the content item data at `page.item`. Content item has `system` and `elements` read accessors. Elements is a hash object with element value mapped to the element's codename. For a detailed object information see [System](https://developer.kenticocloud.com/reference#section-system-object-content-item) and [Element](https://developer.kenticocloud.com/v1/reference#content-type-element-object).

### Linked items

Linked items can be retrieved by calling `get_links(element_codename)`. Returns array of content items with the same model.

### Rich text content

Content of rich text element can be process by calling `get_string(element_codename)` which will resolve all content item links and inline content items based on your resolvers. See rich text resolvers below.

You can find detailed information about the model methods [here](https://github.com/Kentico/delivery-sdk-ruby/blob/e11492754dfec7add748b642a7ff50cb35e749ea/lib/delivery/models/content_item.rb)

## Plugins

Plugins allow you to modify the generator behavior and will be automatically loaded from
`_plugins/kentico/` directory and its subdirectories. The resolver class name should correspond
with the classname specified in the config.

### Content resolvers

To override default content generation, specify a content resolver. `resolve(item)` method is required.

```ruby
class ContentResolver
  def resolve(item)
    type = item.system.type

    case type
    when 'home' then resolve_home item
    else 'Content is missing'
    end
  end
```

### Front Matter resolvers

You can merge the default front matter with additional data. `resolve(item, page_type)` method is required.
page_type is one of ['page', 'post'].

```ruby
class FrontMatterResolver
  def resolve(item, page_type)
    @item = item

    {
      permalink: get_permalink(item, page_type),
      language: item.system.language,
    }
  end
end
```

### Filename resolvers

Specify a filename resolver to resolve filenames for your content. `resolve(item)` method is required. Output should be with an extension.

```ruby
class FilenameResolver
  def resolve(item)
    "#{item.elements.slug.value}-#{item.system.language}"
  end
end
```

### Data resolvers

Specify a data resolver to resolve content item for your data items. `resolve(item)` method is required.

```ruby
class DataResolver
  def resolve(item)
    item.elements.to_h.values
  end
end
```

### Rich text resolvers

Rich text's inline items are outputted as `<object>` element by default and content item
links contains invalid url. To display your content properly, you need to add rich text resolver plugins.

#### Content links

You must define resolve_link method. `Content link` object has following attributes:
- **id**: the system.id of the linked content item
- **code_name**: the system.codename of the linked content item
- **type**: the content type of the linked content item
- **url_slug**: the URL slug of the linked content item, or nil if there is none

You can also define the resolve_404 method taking just the content item system id to produce a reference for items which does not exist anymore.

```ruby
class ContentLinkResolver < KenticoCloud::Delivery::Resolvers::ContentLinkResolver
  def resolve_link(link)
    <<~LINK
      {% assign link_id = '#{link.id}' %}
      {{ site.pages | where_exp: 'page', 'page.item.system.id == link_id' | map: 'url' | first | relative_url }}
    LINK
  end

  def resolve_404(_id)
    '{{ not_found.html | relative_url }}'
  end
end
```

#### Inline items

To override the default `<object>` element you must define `resolve_item` method.

```ruby
class InlineContentItemResolver < KenticoCloud::Delivery::Resolvers::InlineContentItemResolver
  def resolve_item(item)
    type = item.system.type

    case type
    when 'author'
      resolve_author item
    else
      ''
    end
  end

  private

  def resolve_author(author)
    "#{author.elements.name.value}"
  end
end

```
