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
    url = storage.url("foo.jpg")
    url.should contain("bucket")
    url.should contain("foo.jpg")

    prefixed = Shrine::Storage::S3.new("bucket", client, "prefix")
    prefixed_url = prefixed.url("foo.jpg")
    prefixed_url.should contain("bucket")
    prefixed_url.should contain("prefix/foo.jpg")
  end

  it "uses custom endpoint host for URLs" do
    client = Awscr::S3::Client.new("key", "secret", "us-east-2", endpoint: "http://localhost:9000")
    storage = Shrine::Storage::S3.new("bucket", client)

    url = storage.url("foo.jpg")
    url.should contain("localhost:9000")
    url.should contain("bucket")
    url.should contain("foo.jpg")
  end

  it "uses custom endpoint with non-default port" do
    client = Awscr::S3::Client.new("key", "secret", "us-east-2", endpoint: "http://127.0.0.1:9000")
    storage = Shrine::Storage::S3.new("bucket", client)

    url = storage.url("foo.jpg")
    url.should contain("127.0.0.1:9000")
    url.should contain("bucket")
    url.should contain("foo.jpg")
  end

  it "allows overriding host via :host option" do
    client = Awscr::S3::Client.new("key", "secret", "us-east-2")
    storage = Shrine::Storage::S3.new("bucket", client)

    url = storage.url("foo.jpg", host: "cdn.example.com")
    url.should contain("cdn.example.com")
    url.should contain("bucket")
    url.should contain("foo.jpg")
  end

  it "accepts different HTTP methods without raising" do
    client = Awscr::S3::Client.new("key", "secret", "us-east-2")
    storage = Shrine::Storage::S3.new("bucket", client)

    # These should all succeed and return a URL string
    storage.url("foo-get.jpg", method: :get).should be_a(String)
    storage.url("foo-put.jpg", method: :put).should be_a(String)

    # Unknown/unsupported methods should gracefully fall back to :get
    storage.url("foo-head.jpg", method: :head).should be_a(String)
    storage.url("foo-post.jpg", method: :post).should be_a(String)
    storage.url("foo-unknown.jpg", method: :unknown).should be_a(String)
  end
end
