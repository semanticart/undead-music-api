class SuggestedLink
  include RFC822

  include Mongo
  include MongoMapper::EmbeddedDocument

  key :url,           String
  key :count,         Integer
  key :notes,         String
  key :suggested_by,  String

  validates_presence_of :url, :suggested_by
  validates_format_of :url, :with => URI::regexp(%w(http https)), :message => "should be a full http path"
  validates_format_of :suggested_by, :with => EmailAddress, :message => "is not a valid email address"
end
