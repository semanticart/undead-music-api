# TODO: better and static messages on 404 and usage
require 'rubygems'
require 'json'
require 'sinatra'
require 'i18n'
require 'mongo_mapper'
require 'lib/pretty_errors'

SUGGESTED_LINK_USAGE = {:usage => %(#TODO: Please provide a valid mbid as a param (i.e. mbid=blah-blah-blah))}

configure do
  MongoMapper.database = "undeadmusic"

  require 'lib/link'
  require 'lib/suggested_link'
  require 'lib/artist'
end

not_found do
  # TODO: this message should direct to an api description/example page
  {:error => "404: Not found"}.to_json
end

# borrowed from http://blog.nuclearsquid.com/writings/multi-routing
def get_or_post(url, verbs = %w(get post), &block)
  verbs.each do |verb|
    send(verb, url, &block)
  end
end

# TODO: CHANGE BACK TO POST
get_or_post '/api/suggestions' do
  # todo move validations to SuggestedLink itself
  artist = params[:mbid] && Artist.first(:mid => params[:mbid])
  if artist
    suggested_link = SuggestedLink.new(params)
    if suggested_link.valid?
      artist.suggested_links << suggested_link
      suggested_link.attributes.to_json
    else
      {:error => suggested_link.pretty_errors}.merge(SUGGESTED_LINK_USAGE).to_json
    end
  else
    {:error => "Your artist could not be found."}.merge(SUGGESTED_LINK_USAGE).to_json
  end
end

get_or_post '/api/artists/list.json' do
  if params[:q]
    Artist.updated_versions_of(:all_matching, params[:q].downcase.split('|'))
  elsif params[:mbids]
    Artist.updated_versions_of(:all_with_mids, params[:mbids].split('|'))
  elsif params[:names]
    Artist.updated_versions_of(:all_with_name_or_alias, params[:names].split('|'))
  elsif params[:all]
    Artist.all
  else
    {:error => "You must pass params.  Either pass mbids=mbid1|mbid2|mbid3 or names=name1|name2|name3 or q=name1|mbid1|name2|mbid2 or pass all=true."}
  end.to_json
end

get_or_post '/api/artists/show.json' do
  if params[:mbid]
    Artist.first(:mid => params[:mbid])
  elsif params[:name]
    Artist.first_with_name_or_alias(params[:name])
  else
    {:error => "You must specify a name or mbid in your params"}
  end.to_json
end

get '/api/tags/list.json' do
  # TODO: cache this
  tags = Artist.all(:verified => true).map{|a| a.tags}.flatten
  tags.inject({}){|hash,g| hash[g] ||= 0; hash[g] += 1; hash}.to_json
end

get '/' do
  erb :index
end
