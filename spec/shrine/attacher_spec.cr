require "../spec_helper"

describe Shrine::Attacher do
  it "assigns and uploads to cache" do
    attacher = Shrine::Attacher.new
    attacher.attach_cached(IO::Memory.new("data"))

    attacher.file.should be_a(Shrine::UploadedFile)
    attacher.cached?.should be_true
  end

  it "promotes cached file to store" do
    attacher = Shrine::Attacher.new
    attacher.attach_cached(IO::Memory.new("data"))
    attacher.cached?.should be_true

    attacher.promote
    attacher.stored?.should be_true
  end

  it "serializes and loads data" do
    attacher = Shrine::Attacher.new
    attacher.attach(IO::Memory.new("data"))
    data = attacher.data

    loaded = Shrine::Attacher.from_data(data)
    loaded.file.should_not be_nil
    loaded.file.not_nil!.id.should eq attacher.file.not_nil!.id
  end
end
