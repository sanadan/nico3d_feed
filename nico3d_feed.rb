#!/usr/bin/env ruby

require 'rss'
require 'mechanize'

$title = '新着 - ニコニ立体'
$uri = 'https://3d.nicovideo.jp/search'
$about = $uri
$description = 'ニコニ立体の新着をFeedにします。'
$author = 'sanadan'

def main
  web = Mechanize.new
  page = web.get( $uri )

  page.search( '.work-box' ).each do |data|
    item = {}
    item[ 'link' ] = URI.join( 'http://3d.nicovideo.jp', data.at( 'a' )[ 'href' ] ).to_s
    item[ 'title' ] = data.at( '.work-box-title' ).text
    author = data.at( '.work-box-author' ).text
    thumbnail = URI.join('https://3d.nicovideo.jp', data.at('img')['src']).to_s
    item[ 'content' ] = "<a href=\"#{item[ 'link' ]}\"><img src=\"#{thumbnail}\" border=\"0\">#{item[ 'title' ]}</a> / #{author}"
    item[ 'date' ] = Time.now

    $items << item
  end

  raise "検索結果が正しく取得できませんでした" if $items.size == 0
end

# entry
$items = []
begin
  main
rescue
  item = {}
  item[ 'id' ] = Time.now.strftime( '%Y%m%d%H%M%S' )
  item[ 'title' ] = $!.to_s
  item[ 'content' ] = $!.to_s
  $!.backtrace.each do |trace|
    item[ 'content' ] += '<br>'
    item[ 'content' ] += trace
  end
  item[ 'date' ] = Time.now
  $items << item
end

feed = RSS::Maker.make( 'atom' ) do |maker|
  maker.channel.about = $about
  maker.channel.title = $title
  maker.channel.description = $description
  maker.channel.link = $uri
  maker.channel.updated = Time.now
  maker.channel.author = $author
  $items.each do |data|
    item = maker.items.new_item
    item.id = data[ 'id' ]
    item.title = data[ 'title' ]
    item.link = data[ 'link' ] if data[ 'link' ]
    item.content.content = data[ 'content' ]
    item.content.type = 'html'
    item.date = data[ 'date' ]
  end
end

File.write( '/var/www/nico3d_feed/html/feed.xml', feed )
#print feed

