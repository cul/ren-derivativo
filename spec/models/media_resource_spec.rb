require 'rails_helper'

RSpec.describe MediaResource, type: :model do

  context "#initialize" do
    it "raises an error because MediaResource is not supposed to be instantiated" do
      expect{ MediaResource.new('id_does_not_matter_here') }.to raise_error(RuntimeError)
    end
  end

end
