class DbCacheRecord < ApplicationRecord
  serialize :data, HashWithIndifferentAccess
end
