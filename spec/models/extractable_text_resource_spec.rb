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

end
