require "../spec_helper"

describe Shrine::UploadedFile do

  after_each do
    clear_storages
  end

  it "initializes metadata if absent" do
    file = Shrine::UploadedFile.new("id", "cache")
    file.metadata.should be_a(Shrine::UploadedFile::MetadataType)
  end

  describe "#original_filename" do
    it "returns nil when missing" do
      file = Shrine::UploadedFile.new("id", "cache")
      file.original_filename.should be_nil
    end

    it "returns from metadata when present" do
      metadata = Shrine::UploadedFile::MetadataType{"filename" => "foo.jpg"}
      file = Shrine::UploadedFile.new("id", "cache", metadata)
      file.original_filename.should eq "foo.jpg"
    end
   end

  describe "#extension" do
    it "uses id extension when present" do
      file = Shrine::UploadedFile.new("foo.jpg", "cache")
      file.extension.should eq "jpg"
    end

    it "is nil without extension" do
      file = Shrine::UploadedFile.new("foo", "cache")
      file.extension.should be_nil
    end

    it "uses filename from metadata" do
      metadata = Shrine::UploadedFile::MetadataType{"filename" => "foo.jpg"}
      file = Shrine::UploadedFile.new("id", "cache", metadata)
      file.extension.should eq "jpg"
    end
  end

  describe "#size" do
    it "returns nil when missing" do
      file = Shrine::UploadedFile.new("id", "cache")
      file.size.should be_nil
    end

    it "returns integer size" do
      metadata = Shrine::UploadedFile::MetadataType{"size" => 50}
      file = Shrine::UploadedFile.new("id", "cache", metadata)
      file.size.should eq 50
    end

    it "parses string size" do
      metadata = Shrine::UploadedFile::MetadataType{"size" => "50"}
      file = Shrine::UploadedFile.new("id", "cache", metadata)
      file.size.should eq 50
    end
  end

  describe "#mime_type/#content_type" do
    it "returns mime_type from metadata" do
      metadata = Shrine::UploadedFile::MetadataType{"mime_type" => "image/jpeg"}
      file = Shrine::UploadedFile.new("id", "cache", metadata)

      file.mime_type.should eq "image/jpeg"
      file.content_type.should eq "image/jpeg"
    end

    it "returns nil when missing" do
      file = Shrine::UploadedFile.new("id", "cache")
      file.mime_type.should be_nil
      file.content_type.should be_nil
    end
  end

  it "closes underlying IO on #close" do
    uploader = Shrine.new("store")
    file = uploader.upload(fakeio)
    io = file.io
    file.close
    io.closed?.should be_true
  end

  it "delegates #url/#exists?/#delete to storage" do
    storage = Shrine::Storage::Memory.new
    Shrine.settings.storages["store"] = storage
    storage.upload(fakeio("data"), "id")

    file = Shrine::UploadedFile.new("id", "store")
    file.url.should eq "memory://id"
    file.exists?.should be_true

    file.delete
    file.exists?.should be_false
  end

  it "streams and downloads" do
    storage = Shrine::Storage::Memory.new
    Shrine.settings.storages["store"] = storage
    storage.upload(fakeio("data"), "id")
    file = Shrine::UploadedFile.new("id", "store")

    io = IO::Memory.new
    file.stream(io)
    io.to_s.should eq "data"

    tempfile = file.download
    File.read(tempfile.path).should eq "data"
    tempfile.close
    tempfile.delete
  end
end
