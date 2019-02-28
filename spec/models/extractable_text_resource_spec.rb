require 'rails_helper'

RSpec.describe ExtractableTextResource, type: :model do

  subject {
    # Mock implementation of GenericResource#with_ds_resource so we don't try to make a call to Fedora for this test
    allow_any_instance_of(GenericResource).to receive(:with_ds_resource).and_return(nil)
    allow_any_instance_of(GenericResource).to receive(:save).and_return(nil)
    allow(File).to receive(:size).and_return(1)

    fedora_extractable_text_generic_resource = GenericResource.new(pid: 'pdf:object')
    fedora_extractable_text_generic_resource.add_datastream(fedora_extractable_text_generic_resource.create_datastream(
			ActiveFedora::Datastream,
      'content',
			:controlGroup => 'M',
			:mimeType => 'application/pdf',
			:dsLabel => "file.pdf",
			:versionable => false
		))
    ExtractableTextResource.new(fedora_extractable_text_generic_resource)
  }

  context "#queue_fulltext_extraction" do
    it "queues a fulltext extraction job" do
      expect(Resque).to receive(:enqueue_to).with(Derivativo::Queue::TEXT_EXTRACTION_LOW, ExtractFulltextJob, subject.id, Time.now.to_s)
      subject.queue_fulltext_extraction
    end
  end

  context "#extract_fulltext_if_not_exist" do
    it "returns early and does not try to create a new datastream if a fulltext datastream already exists" do
      allow(subject.fedora_object).to receive(:datastreams).and_return({'fulltext' => 'pretend this is a datastream value'})
      expect(subject.fedora_object).not_to receive(:create_datastream)
      subject.extract_fulltext_if_not_exist
    end
  end

  context "#create_access_copy_if_not_exist" do
    it "creates derivative in expected location and sets access datastream RELS-INT :rdf_type equal to ServiceFile" do
      expect(subject.create_access_copy_if_not_exist).to eq("/Users/Shared/derivativo_test_home/f7/93/75/f79375c0cf8084b91d125dc9db9d1291e3db342a616ea31def0765827c171a76/access.pdf")
      expect(
        subject.fedora_object.rels_int.relationships(
          subject.fedora_object.datastreams[MediaResource::ACCESS_DATASTREAM_NAME], :rdf_type
        ).first.object.value
      ).to eq('http://pcdm.org/use#ServiceFile')
    end
  end

end
