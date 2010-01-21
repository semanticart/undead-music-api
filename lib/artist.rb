class Artist
  LAST_FM_KEY = JSON.load(File.read(File.dirname(__FILE__) + "/../config.json"))['last_fm_key']
  JSON_EXCLUSIONS = %w(last_fm last_fm_update tags aliases)

  require 'open-uri'
  require 'nokogiri'

  include Mongo
  include MongoMapper::Document

  key :mid,           String, :index => true
  key :last_fm_url,   String
  key :thumbnail,     String
  key :verified,      Boolean, :default => false
  key :name,          String, :index => true
  key :last_fm,       String
  key :last_fm_update,Time
  key :aliases,       Array, :index => true
  key :tags,          Array, :index => true

  many :links

  before_save :downcase_name_and_aliases

  def update_last_fm
    unless mid.blank?
      begin
        res = open("http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&mbid=#{self.mid}&api_key=#{LAST_FM_KEY}").read
        self.last_fm = res
        self.last_fm_update = Time.now
        update_attributes_from_last_fm!
      rescue => ex
        # TODO: error handling
        p "uh oh:", ex
      end
    end
  end

  def update_attributes_from_last_fm! mid = false
    doc = Nokogiri::XML(self.last_fm)

    thumb = (node = doc.search('image[size=medium]')[0]) && node.inner_text
    self.thumbnail = thumb unless thumb.blank?

    if mid
      tmp = doc.search("mbid").first.inner_text rescue nil
      self.mid = (tmp.blank? ? nil : tmp)
    end

    tmp_tags = doc.search("artist/tags/tag/name").map{|x| x.inner_text}
    self.tags = tmp_tags.sort unless tmp_tags.blank? or tmp_tags.sort == self.tags

    self.last_fm_url = (node = doc.search('url').first) && node.inner_text
    self.save!
  end

  def verify!
    self.update_attributes(:verified => true)
  end

  def de_last_fm!
    self.last_fm = nil
    self.last_fm_update = nil
    self.thumbnail = nil
    self.save!
  end

  def demid!
    self.mid = nil
    de_last_fm!
  end

  def self.updated_versions_of(sym, arg)
    send(sym, arg).map do |artist|
      # if it is empty or older than a week, we update it
      if artist.last_fm_update.nil? or artist.last_fm_update < Date.today - 7
        artist.update_last_fm
      end
      artist
    end
  end

  def self.all_with_mids(mids)
    Artist.all(:conditions => {:mid => mids})
  end

  def self.first_with_name_or_alias name
    use_name = name.downcase.gsub(/\'/, "\\\\'")
    Artist.send(:initialize_doc,
      Artist.collection.find_one("$where" => Code.new("this.name == '#{use_name}' || this.aliases.indexOf('#{use_name}') > -1"))
    )
  end

  def self.all_matching(array)
    all = Artist.all(:name => array) + Artist.all(:aliases => array) + Artist.all(:mid => array)
    # this simply squashes everything of the same object id to prevent duplicates
    all.inject({}){|hash, item| hash[item.id] = item; hash}.values
  end

  def self.all_with_name_or_alias artist_names
    artist_names = [*artist_names].map{|x| x.downcase}

    # TODO: use $where statement like above
    matches = Artist.all(:conditions => {:name => artist_names})
    matches + Artist.all(:conditions => {:aliases => (artist_names - matches.map{|x| x.name})})
  end

  def downcase_name_and_aliases
    self.name = self.name.downcase
    self.aliases = self.aliases.map{|x| x.downcase}
  end

  def to_json(args = nil)
    self.attributes.reject{|k,v| JSON_EXCLUSIONS.include?(k)}.to_json
  end
end
