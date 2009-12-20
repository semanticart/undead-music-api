class Link
  include Mongo
  include MongoMapper::EmbeddedDocument

  key :url,         String
  key :alt_url,     String
  key :count,       Integer
end
