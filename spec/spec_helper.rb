# frozen_string_literal: true
require 'jekyll'
require 'ostruct'
require 'json'
require 'capybara/dsl'
require 'capybara/rspec'
require 'rack/jekyll'
require 'fileutils'
require File.expand_path('../lib/jekyll-kentico', __dir__)

Jekyll.logger.log_level = :error

def to_openstruct(hash)
  JSON.parse(hash.to_json, object_class: OpenStruct)
end

class TestItem
  def initialize(system, elements)
    @system = to_openstruct(system)
    @elements = to_openstruct(elements)
  end

  def system
    @system
  end

  def elements
    @elements
  end

  def get_string(code_name)
    element = @elements[code_name]
    element.value if element
  end
end

class TestImporter
  def initialize(config)
  end

  def items_by_type(language)
    @items_by_type ||= {
      'pages_defaults' => [
        create_item('default_content', 'pages_defaults', language, {
          content: create_text('Text', 'Default content'),
        }),
        create_item('default_title', 'pages_defaults', language, {
          title: create_text('Title', 'Default title'),
        }),
      ],
      'posts_defaults' => [
        create_item('default_date', 'posts_defaults', language, {
          date: create_date('Date', '2019-12-09T16:29:11+0000'),
        }),
        create_item('default_tags', 'posts_defaults', language, {
          date: create_date('Date', '2019-12-10T16:29:11+0000'),
          tags: create_taxonomy('Tags', 'tags', [
            create_taxonomy_term('Tag1', 'tag1'),
            create_taxonomy_term('Tag2', 'tag2'),
          ]),
        }),
        create_item('default_categories', 'posts_defaults', language, {
          date: create_date('Date', '2019-12-11T16:29:11+0000'),
          categories: create_taxonomy('Categories', 'categories', [
            create_taxonomy_term('Category1', 'category1'),
            create_taxonomy_term('Category2', 'category2'),
          ]),
        }),
        create_item('default_data', 'pages_defaults', language, {
          date: create_date('Date', '2019-12-12T16:29:11+0000'),
          asset: create_asset('Asset', 'test_asset_url'),
        }),
      ],
      'overridden_defaults' => [
        create_item('overridden_title', 'overridden_defaults', language, {
          overridden_title: create_text('Overridden title', 'Overridden title'),
        }),
        create_item('overridden_content', 'overridden_defaults', language, {
          overridden_content: create_text('Overridden content', 'Overridden content'),
        }),
      ],
    }
  end

  def taxonomies
    {}
  end

  private

  def create_item(codename, type, language, elements)
    TestItem.new(
    { codename: codename, id: codename, language: language, type: type },
      elements,
    )
  end

  def create_asset(name, url)
    {
      name: name,
      type: 'asset',
      value: [{ url: url }],
    }
  end

  def create_text(name, text)
    {
      name: name,
      type: 'text',
      value: text,
    }
  end

  def create_date(name, iso8601_value)
    {
      name:name,
      type: 'date_time',
      value: iso8601_value,
    }
  end

  def create_taxonomy(name, taxonomy_group_codename, value)
    {
      name: name,
      taxonomy_group: taxonomy_group_codename,
      type: 'taxonomy',
      value: value,
    }
  end

  def create_taxonomy_term(name, codename)
    {
      name: name,
      codename: codename,
    }
  end
end

ENV['RACK_TEST_IMPORTER'] = TestImporter.to_s

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = :random

  SOURCE_DIR = File.expand_path('fixtures', __dir__)
  DEST_DIR = File.expand_path('dest', __dir__)

  config.include Capybara::DSL

  def source_dir(*files)
    File.join(SOURCE_DIR, *files)
  end

  def dest_dir(*files)
    File.join(DEST_DIR, *files)
  end

  def cleanup_fixture
    FileUtils.rm_rf(dest_dir)
  end

  def default_config
    {
      force_build: true,
      source: source_dir,
      destination: dest_dir,
      future: true,
      permalink: 'pretty',
      kentico: {
        default_layout: 'default',
        pages: {
          pages_defaults: {},
          overridden_defaults: {
            title: 'overridden_title',
            content: 'overridden_content',
          }
        },
        posts: {
          type: 'posts_defaults',
          layout: 'post',
        },
      },
    }
  end

  Capybara.app = Rack::Jekyll.new(default_config)
end