require "../../spec_helper"

describe Shrine::Storage::S3 do
  it "builds object_key with and without prefix" do
    client = Awscr::S3::Client.new("key", "secret", "region")

    storage = Shrine::Storage::S3.new("bucket", client)
    storage.object_key("id").should eq "id"

    storage_prefixed = Shrine::Storage::S3.new("bucket", client, "prefix")
    storage_prefixed.object_key("id").should eq "prefix/id"
  end

  it "generates URLs with and without prefix" do
    client = Awscr::S3::Client.new("key", "secret", "us-east-2")

    storage = Shrine::Storage::S3.new("bucket", client)
    storage.url("foo.jpg").should contain("bucket")
    storage.url("foo.jpg").should contain("foo.jpg")

    prefixed = Shrine::Storage::S3.new("bucket", client, "prefix")
    prefixed.url("foo.jpg").should contain("bucket")
    prefixed.url("foo.jpg").should contain("prefix/foo.jpg")
  end
end
