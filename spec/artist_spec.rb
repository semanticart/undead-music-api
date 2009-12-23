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

  context "#update_attributes_from_last_fm!" do
    def sample_artist last_fm
      Artist.new(:name => "something", :aliases => [], :last_fm => last_fm)
    end

    it "raises no errors if the xml is missing nodes" do
      a = sample_artist("<xml></xml>")
      lambda{
        a.update_attributes_from_last_fm!
      }.should_not raise_error
    end

    it "updates the thumbnail if one is provided in the xml" do
      a = sample_artist(%(<xml><image size="medium">http://something/1.jpg</image></xml>))
      lambda{
        a.update_attributes_from_last_fm!
      }.should change(a, :thumbnail).from(nil).to("http://something/1.jpg")
    end

    it "updates the tags if they are provided in the xml" do
      a = sample_artist(%(<xml><artist><tags><tag><name>something</name></tag><tag><name>something else</name></tag></tags></artist></xml>))
      lambda{
        a.update_attributes_from_last_fm!
      }.should change(a, :tags).from([]).to(["something", "something else"])
    end

    it "updates the last_fm_url if it is provided in the xml" do
      a = sample_artist(%(<xml><url>http://www.last.fm/music/Journey</url></xml>))
      lambda{
        a.update_attributes_from_last_fm!
      }.should change(a, :last_fm_url).from(nil).to("http://www.last.fm/music/Journey")
    end

    context "mid" do
      MBID_PRESENT = %(<xml><mbid>1234567</mbid></xml>)

      it "updates the mid if you pass true and a mbid is present in the xml" do
        a = sample_artist(MBID_PRESENT)
        lambda{
          a.update_attributes_from_last_fm!(true)
        }.should change(a, :mid).from(nil).to('1234567')
      end

      it "does not update the mid if you pass it false" do
        a = sample_artist(MBID_PRESENT)
        lambda{
          a.update_attributes_from_last_fm!
        }.should_not change(a, :mid)
      end

      it "does not update the mid if you pass true but no mbid is present in the xml" do
        a = sample_artist(%(<xml></xml>))
        lambda{
          a.update_attributes_from_last_fm!(true)
        }.should_not change(a, :mid)
      end

      it "does not update hte mid if you pass true but the mbid is blank in the xml" do
        a = sample_artist(%(<xml><mbid></mbid></xml>))
        lambda{
          a.update_attributes_from_last_fm!(true)
        }.should_not change(a, :mid)
      end
    end
  end
end
