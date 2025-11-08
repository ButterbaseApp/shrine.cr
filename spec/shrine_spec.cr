require "./spec_helper"

describe Shrine do
  describe ".with_file" do
    it "yields existing File without closing it" do
      file = File.tempfile("shrine-with-file") do |f|
        f.puts "test"
      end
      file = File.open(file.path)

      Shrine.with_file(file) do |f|
        f.should be_a(File)
        f.path.should eq(file.path)
        f.closed?.should be_false
      end

      file.closed?.should be_false
      file.close
    end

    it "downloads Shrine::UploadedFile to a tempfile" do
      uploader = Shrine.new("cache")
      io = IO::Memory.new("content")
      uploaded = uploader.upload(io)

      Shrine.with_file(uploaded) do |file|
        file.should be_a(File)
        File.read(file.path).should eq("content")
      end
    end

    it "wraps IO into tempfile" do
      io = IO::Memory.new("content")

      Shrine.with_file(io) do |file|
        file.should be_a(File)
        File.read(file.path).should eq("content")
      end

      io.pos.should eq(0)
    end
  end
end
