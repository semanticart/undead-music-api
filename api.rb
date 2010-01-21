# TODO: better and static messages on 404 and usage
require 'rubygems'
require 'json'
require 'sinatra'
require 'i18n'
require 'mongo_mapper'
require 'lib/link'
require 'lib/artist'

configure do
  MongoMapper.database = "undeadmusic"
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

post '/api/suggestions' do
  # new suggestion
  # artist id
  # url
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
    Artist.first(:conditions => {:mid => params[:mbid]})
  elsif params[:name]
    Artist.first_with_name_or_alias(params[:name])
  else
    {:error => "You must specify a name or mbid in your params"}
  end.to_json
end

get '/api/tags/list.json' do
  # TODO: cache this
  tags = Artist.all(:conditions => {:verified => true}).map{|a| a.tags}.flatten
  tags.inject({}){|hash,g| hash[g] ||= 0; hash[g] += 1; hash}.to_json
end

get '/' do
  erb :index
end
