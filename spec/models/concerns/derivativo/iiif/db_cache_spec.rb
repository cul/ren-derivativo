require 'rails_helper'

describe Derivativo::Iiif::DbCache, :type => :unit do
  let(:test_class) do
    _c = Class.new
    _c.send :include, Derivativo::Iiif::DbCache
  end
  
  let(:iiif) do
    test_iiif_object = test_class.new
    test_iiif_object.instance_variable_set(:@id, 'abd:123')
    #allow(test_iiif_object).to receive(:id).and_return('abc:123')
    test_iiif_object
  end
  
  after do
    iiif.db_cache_clear # Clean up the associated database record we're creating when we set db cache keys
  end
  
  context '#db_cache_set' do
    it "doesn't raise an error when setting an allowed key" do
      expect { iiif.db_cache_set(Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY, [100, 200]) }.not_to raise_error
    end
    
    it "raises an error when attempting to set a key that is not allowed" do
      expect { iiif.db_cache_set('bogus-key', 'value') }.to raise_error(Derivativo::Exceptions::InvalidCacheKey)
    end
    
    it "properly sets the cache value" do
      key = Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY
      val = [100, 200]
      iiif.db_cache_set(key, val)
      expect(iiif.db_cache_record.data[key]).to eq(val)
    end
    
    it "serializes data to the database" do
      key = Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY
      val = [100, 200]
      iiif.db_cache_set(key, val)
      
      retrieved_activerecord_object = DbCacheRecord.find_by(pid: iiif.instance_variable_get(:@id))
      expect(retrieved_activerecord_object.data[key]).to eq(val)
    end
  end
  
  context '#db_cache_get' do
    it "doesn't raise an error when getting an allowed key" do
      expect { iiif.db_cache_get(Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY) }.not_to raise_error
      expect { iiif.db_cache_get(Derivativo::Iiif::CacheKeys::REPRESENTATIVE_RESOURCE_CLOSED_KEY) }.not_to raise_error
    end
    
    it "raises an error when attempting to set a key that is not allowed" do
      expect { iiif.db_cache_get('bogus-key') }.to raise_error(Derivativo::Exceptions::InvalidCacheKey)
    end
    
    it "properly get an already-set cache value" do
      key = Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY
      val = [100, 200]
      iiif.db_cache_set(key, val)
      expect(iiif.db_cache_get(key)).to eq(val)
    end
  end
  
  context '#destroy' do
    it "destroys the associated database object" do
      iiif.db_cache_record.save
      expect(DbCacheRecord.find_by(pid: iiif.instance_variable_get(:@id))).not_to be_nil
      
      iiif.db_cache_clear
      expect(DbCacheRecord.find_by(pid: iiif.instance_variable_get(:@id))).to be_nil
    end
  end
  
end