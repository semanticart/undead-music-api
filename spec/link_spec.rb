require File.dirname(__FILE__)+ "/spec_helper.rb"
require File.dirname(__FILE__)+ "/../lib/link.rb"

describe Link do
  before(:each) do
    @archive_link = Link.new(:alt_url => "http://s.com/a/5", :count => 12, :url => "http://s.com/a/5/bb")
  end

  it "has specs... #TODO: this is mostly covered by artist_spec.rb"
end
