require 'rails_helper'

RSpec.describe DbCacheRecord, type: :model do
  context "#initialize" do
    subject { DbCacheRecord.new }
    it "has an empty hash in its data attribute" do
      expect(subject.data).to eq({})
    end
  end
  
  context "#data" do
    subject {
      db_cache_record = DbCacheRecord.new
      db_cache_record.data[:symbol_key] = 'some value'
      db_cache_record.data['string_key'] = 'some other value'
      db_cache_record
    }
    after { subject.destroy }
    
    it "is a HashWithIndifferentAccess field" do
      expect(subject.data[:symbol_key]).to eq('some value')
      expect(subject.data['symbol_key']).to eq('some value')
      expect(subject.data[:string_key]).to eq('some other value')
      expect(subject.data['string_key']).to eq('some other value')
    end
    
    it "properly serializes and deserializes as a HashWithIndifferentAccess upon save and subsequent db retrieval" do
      subject.save
      record_retrieved_from_db = DbCacheRecord.find(subject.id)
      expect(record_retrieved_from_db.data[:symbol_key]).to eq('some value')
      expect(record_retrieved_from_db.data['symbol_key']).to eq('some value')
      expect(record_retrieved_from_db.data[:string_key]).to eq('some other value')
      expect(record_retrieved_from_db.data['string_key']).to eq('some other value')
    end
  end
end
