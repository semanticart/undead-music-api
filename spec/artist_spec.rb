require File.dirname(__FILE__)+ "/spec_helper.rb"
require File.dirname(__FILE__)+ "/../lib/link.rb"
require File.dirname(__FILE__)+ "/../lib/artist.rb"

describe Artist do
  before(:all) do
    Artist.delete_all
    @@pumpkins  = Artist.create(:name => "The Smashing Pumpkins", :aliases => ["Smashing Pumpkins", "Smashing Pumpkins, The"])
    @@ed        = Artist.create(:name => "Ed's", :aliases => ["Ed's Band"])
 end

  context "with an archive_link" do
    before(:all) do
      @@link = Link.new(:url => "http://s.com/a/5", :count => 12, :alt_url => "http://s.com/a/5/bb")
      @@pumpkins.links << @@link
      @@pumpkins.save!
    end

    it "saves both the artist and the archive_link" do
      found_artist = Artist.first(:name => @@pumpkins.name)
      found_artist.links.should == [@@link]
      found_artist.links.first.count.should == 12
    end
  
    it "can update an link" do
      new_link =  @@link.dup
      new_link.count = 22
      @@pumpkins.update_attributes(:links => [new_link])

      Artist.first_with_name_or_alias(@@pumpkins.name).links.first.count.should == 22
    end
  end

  context "with aliases" do
    it "can find artists by aliases" do
      Artist.first(:conditions => {:aliases => [@@pumpkins.aliases.first]}).name.should == @@pumpkins.name
    end
  end

  context "finding an artist" do
    it "finds an artist by name or alias" do
      Artist.first_with_name_or_alias("The Smashing Pumpkins").should == @@pumpkins
      Artist.first_with_name_or_alias("Smashing Pumpkins").should == @@pumpkins
    end

    it "finds an artist by name or alias when that name contains apostrophes" do
      Artist.first_with_name_or_alias("Ed's").should == @@ed
      Artist.first_with_name_or_alias("Ed's Band").should == @@ed
    end
  end

  context "finding all artists by name/alias" do
    it "finds multiple matches" do
      Artist.all_with_name_or_alias(["Ed's", "Smashing Pumpkins"]).should =~ [@@ed, @@pumpkins]
    end

    it "returns an empty array if there are no matches" do
      Artist.all_with_name_or_alias(["Some unknown artist"])
    end
  end
end
