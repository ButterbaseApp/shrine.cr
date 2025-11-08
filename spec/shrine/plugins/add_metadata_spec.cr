require "../../spec_helper"
require "../../../src/shrine/plugins/add_metadata"

class ShrineWithAddMetadata < Shrine
  load_plugin Shrine::Plugins::AddMetadata

  # redefine Shrine#extract_metadata to make it public
  def extract_metadata(io : IO, **options) : Shrine::UploadedFile::MetadataType
    super
  end

  add_metadata :custom, ->{
    "value"
  }

  add_metadata :multiple_values, ->{
    text = io.gets_to_end

    Shrine::UploadedFile::MetadataType{
      "custom_1" => text,
      "custom_2" => text * 2,
    }
  }

  finalize_plugins!
end

describe Shrine::Plugins::AddMetadata do


  describe "Shrine.add_metadata" do
    describe "with argument" do
      it "adds declared metadata" do
        uploader = ShrineWithAddMetadata.new("store")
        metadata = uploader.extract_metadata(fakeio)

        metadata["custom"].should eq "value"
        metadata["size"].should be_a(Int32)
      end

      it "adds the metadata method to UploadedFile" do
        uploader = ShrineWithAddMetadata.new("store")
        uploaded_file = uploader.upload(fakeio)

        uploaded_file.metadata["custom"].should eq "value"
      end
    end

    describe "with multiple metadata values" do
      it "adds declared metadata" do
        uploader = ShrineWithAddMetadata.new("store")
        io = fakeio("text")
        metadata = uploader.extract_metadata(io)

        metadata["custom_1"].should eq "text"
        metadata["custom_2"].should eq "text" * 2
        metadata["size"].should be_a(Int32)
      end

      it "adds the metadata method to UploadedFile" do
        uploader = ShrineWithAddMetadata.new("store")
        io = fakeio("text")
        uploaded_file = uploader.upload(io)

        uploaded_file.metadata["custom_1"].should eq "text"
        uploaded_file.metadata["custom_2"].should eq "text" * 2
      end
    end
  end
end
