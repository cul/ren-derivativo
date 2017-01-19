class DbCacheRecord < ActiveRecord::Base
  serialize :data, HashWithIndifferentAccess
end
