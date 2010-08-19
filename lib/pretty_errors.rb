module Mongo
  def pretty_errors
    self.errors.inject({}) do |hash, error|
      hash[error.first] = error.last
      hash
    end
  end
end
