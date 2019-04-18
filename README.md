# Jekyll Kentico

Jekyll Kentico is utilizing Kentico Cloud, headless CMS, as a content repository and integrates
it with Jekyll static site generator. You can generate posts, pages, collections and data items.

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
  default_layout: default                                      
  content_item_resolver: ContentItemResolver                  
  content_link_resolver: ContentLinkResolver                  
  inline_content_item_resolver: InlineContentItemResolver     
  max_linked_items_depth: 0                                   # Defaults to 1
  posts:                                                      
    content_type: blog_post                                   
    layout: post
    date: date_element_codename                               # Defaults to 'date'
    content: content_element_codename                         # Defaults to 'content'             
  pages:                                                      
    index: home_page                                          
    layout: page                                              
    content_types:                                            
      page:
        content: content_element_codename                     # Defaults to 'content'                                                   
        layouts:                                              
          home_page: home
          authors_page: authors
          categories_page: categories
          cities_page: cities
      author:                                           
        layout: author                                        
        collection: authors                                   
      category:
        layout: category
        collection: categories
      city:
        layout: city
        collection: cities
  data:
    navigation_item:
      name: navigation                                          # Defaults to used content type codename
  taxonomies:                                                 
    - site                                                    
```

Parameter                       | Description
----------                      | ------------
project_id                      | Kentico Cloud project id
secure_key                      | Delivery secure key for the project
default_layout                  | Default layout filename without the extension used for all content
content_item_resolver           | Class name of the mapper
content_link_resolver           | Class name of the mapper
inline_content_item_resolver    | Class name of the mapper
max_linked_items_depth          | Maximum depth of resolved linked items
layout                          | Layout filename without the extension for a particular content type
layouts                         | Hash of specific layouts based on content item codename
content_type                    | Content type codename
content_types                   | Hash of content_type parameters
index                           | Codename of content item used to generate the index page
name                            | Name data items accessor
date                            | Content item element codename used for post date
content                         | Content item element codename used for post and page content

## Posts

All generated posts will be merged with content from the _posts directory.

To generate posts you need to specify posts part of your config and the post's content type.
Layout, date and content are optional parameters.

The content item is required to have
a DateTime element filled. The date parameter codename defaults to `date`. Parameter codename
for the post content defaults to `content`.

## Pages

All generated pages will be merged with pages located in the root directory of your Jekyll project.

You can specify a default layout for all pages. 
Parameter codename for the page content defaults to `content`.

## Index page

if you want your index page to be generated with extra data from Kentico Cloud
then you can specify content item's codename in the config.

## Collections

You can add pages to Jekyll collections. Add a collection name to config and it will be
accessible through the site global variable as usual. for example `site.categories`. 

## Layouts

Jekyll posts and pages do not have any default layouts. You can specify a default layout
for all content. The layout name should correspond to your layout's filename without the
extension. Each content type can be associated with different layout and you can also 
override the layout for individual pages based on their content item's codename.

## Data items

You can generate data items to be accessible through the `site.data`. Add the data part to your
config and all content types will be added to accessor based on their content types codename.
You can override the accessor's name with name parameter in the config.

### Taxonomies

Taxonomies will be stored in `site.data.taxonomies`. They can be used for modeling site navigation.

## Content data

By default you can access the content item data at `page.system` and `page.elements`. Elements is
 a hash object with element value mapped to the element's codename. For a detailed
 object information see [System](https://developer.kenticocloud.com/v1/reference#content-item-object)
 and [Element](https://developer.kenticocloud.com/v1/reference#content-type-element-object).

You can customize this the generated data with an item resolver plugin. See below.

## Plugins

Plugins allow you to modify the generator behavior and will be automatically loaded from
`_plugins/kentico/` directory and its subdirectories. The resolver class name should correspond
with the classname specified in the config.
    
### Item resolvers

You can override the page data generation, by adding a content item resolver
plugin. You must define resolve_item method, which will return the page data.

If you want to use linked items then you need to resolve them manually by
calling `get_links` on the content item and by calling `get_string` to process the rich text element.

If you want to alter the item element resolving then override `resolve_element` method.
This method receives params object as an argument.

Params attributes
- **element**: element of item.elements, it has an additional codename attribute
- **get_links**: takes element codename and returns array of ContentItems
- **get_string**:  takes element codename and returns rich text value as a html string

```ruby
class ContentItemResolver < Jekyll::Kentico::Resolvers::ContentItemResolver
  def resolve_item(item)
    case item.system.type
    when 'city'
      {
        city_name: item.elements.name.value,
        description: item.get_string('description'),
        image_url: item.elements.picture.value[0].url,
        nearby_cities: item.get_links('nearby_cities')
      }
    else
      super
    end
  end
  
  def resolve_element(params)
      element = params.element
  
      case element.type
      when Jekyll::Kentico::Constants::ItemElementType::ASSET
        element.value.map { |asset| asset['url'] }
      when Jekyll::Kentico::Constants::ItemElementType::RICH_TEXT
        params.get_string.call(element)
      when Jekyll::Kentico::Constants::ItemElementType::LINKED_ITEMS
        params.get_links.call(element).map(&method(:resolve_item))
      else
        element.value
      end
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

To help you construct your url correctly, you can access base url of your site at `@base_url` instance variable.

```ruby
class ContentLinkResolver < Jekyll::Kentico::Resolvers::ContentLinkResolver
  def resolve_link(link)
    url = get_url link
    url && "#{@base_url}/#{url}"
  end

private
  def get_url(link)
    "authors/#{link.code_name}" if link.type == 'author'
  end
end
```

#### Inline items

To override the default `<object>` element you must define `resolve_content_item` method.

```ruby
class InlineContentItemResolver < Jekyll::Kentico::Resolvers::InlineContentItemResolver
  def resolve_content_item(item)
    type = item.system.type

    case type
    when 'author'
      resolve_author(item)
    else nil
    end
  end

private
  def resolve_author(author)
    "<h1>#{author.elements.name}</h1>"
  end
end
```

#### Linked items

You need to override the content item resolver and define the `resolve_element(params)` method to include linked items.
See `ContentItemResolver` section above.

## Secure variables

You can use environment variables to hide your secrets from a public config.
To do so, you need to prefix the project id and secure key values with `ENV_`.
For example the `PROJECT_ID` and `DELIVERY_API_KEY` variables will be used. 

```yaml
kentico:
  project_id: ENV_PROJECT_ID
  secure_key: ENV_DELIVERY_API_KEY
```

## Examples

For a working example see [this project](https://github.com/RadoslavK/jekyll-blog).