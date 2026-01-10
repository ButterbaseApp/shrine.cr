# Ralph ORM integration plugin for Shrine
#
# This plugin provides seamless integration between Shrine file uploads
# and Ralph ORM models. It automatically handles:
# - Storing attachment metadata as JSON in a database column
# - Promoting files from cache to store on save
# - Deleting files when records are destroyed
#
# ## Usage
#
# First, load the plugin on your uploader:
#
# ```crystal
# require "shrine/plugins/ralph"
#
# class ImageUploader < Shrine
#   load_plugin(Shrine::Plugins::Ralph)
#   finalize_plugins!
# end
# ```
#
# Then use the `shrine_attachment` macro in your Ralph model:
#
# ```crystal
# class Photo < Ralph::Model
#   table :photos
#
#   column id : Int64, primary: true
#   column image_data : String?  # Stores the JSON serialized attachment
#
#   shrine_attachment :image, ImageUploader
# end
# ```
#
# Now you can use it:
#
# ```crystal
# # Create with file upload
# photo = Photo.new
# photo.image = File.open("photo.jpg")
# photo.save  # Promotes from cache to store
#
# # Access the uploaded file
# photo.image.try &.url  # => "https://..."
#
# # Change attachment
# photo.image = File.open("new_photo.jpg")
# photo.save  # Deletes old file, promotes new one
#
# # Remove attachment
# photo.image = nil
# photo.save  # Deletes the file
#
# # Destroy record
# photo.destroy  # Deletes the attached file
# ```
#
# ## Database Column
#
# The attachment data is stored as JSON in a TEXT/VARCHAR column. The column
# name follows the pattern `{name}_data`. For example, `shrine_attachment(:image, ...)`
# expects an `image_data` column. You can override this with the `column` parameter:
#
# ```crystal
# shrine_attachment :avatar, ImageUploader, column: :avatar_json
# ```
#
# ## Callbacks
#
# The plugin registers callbacks on the model:
# - `@[AfterSave]`: Promotes cached files to permanent storage
# - `@[AfterDestroy]`: Deletes the attached file
#

class Shrine
  module Plugins
    module Ralph
      # Module mixed into the Attacher class to add column serialization support
      module AttacherMethods
        # Load attachment from column data (JSON string)
        def load_column(data : String) : Shrine::UploadedFile?
          return nil if data.empty?
          parsed = Hash(String, String | UploadedFile::MetadataType).from_json(data)
          load_data(parsed)
          file
        end

        def load_column(data : Nil) : Nil
          load_data(nil)
          nil
        end

        # Get attachment data as JSON string for storing in column
        def column_data : String?
          data.try &.to_json
        end
      end
    end
  end
end

# Macro to be used in Ralph models
#
# This macro generates all the necessary methods and callbacks for
# integrating Shrine attachments with Ralph ORM models.
#
# Parameters:
# - name: The attachment name (e.g., :image, :avatar)
# - uploader: The Shrine uploader class to use
# - column: Optional. The database column name (defaults to {name}_data)
#
# Example:
# ```crystal
# class Photo < Ralph::Model
#   column image_data : String?
#   shrine_attachment :image, ImageUploader
# end
# ```
macro shrine_attachment(name, uploader, column = nil)
  {% data_column = column || "#{name.id}_data" %}

  # Instance variable to hold the attacher
  @_shrine_{{name.id}}_attacher : {{uploader}}::Attacher?

  # Track if attachment changed (for callbacks)
  @_shrine_{{name.id}}_changed : Bool = false

  # Get or create the attacher for this attachment
  def {{name.id}}_attacher : {{uploader}}::Attacher
    @_shrine_{{name.id}}_attacher ||= begin
      attacher = {{uploader}}::Attacher.new
      # Load existing data from the column if present
      if data = self.{{data_column.id}}
        attacher.load_column(data) unless data.empty?
      end
      attacher
    end
  end

  # Get the uploaded file
  def {{name.id}} : Shrine::UploadedFile?
    {{name.id}}_attacher.file
  end

  # Assign a new file (caches it) or nil to remove
  def {{name.id}}=(value : IO?)
    if value
      {{name.id}}_attacher.assign(value)
    else
      {{name.id}}_attacher.attach(nil)
    end
    @_shrine_{{name.id}}_changed = true
    # Update the data column immediately so it persists on save
    self.{{data_column.id}} = {{name.id}}_attacher.column_data
  end

  # Assign from an existing UploadedFile
  def {{name.id}}=(value : Shrine::UploadedFile?)
    {{name.id}}_attacher.attach(value)
    @_shrine_{{name.id}}_changed = true
    self.{{data_column.id}} = {{name.id}}_attacher.column_data
  end

  # Check if attachment was changed
  def {{name.id}}_changed? : Bool
    @_shrine_{{name.id}}_changed
  end

  # Finalize the attachment (promote cached -> store, delete previous)
  # Called automatically via AfterSave callback
  @[Ralph::Callbacks::AfterSave]
  def _shrine_finalize_{{name.id}}
    return unless @_shrine_{{name.id}}_changed
    {{name.id}}_attacher.finalize
    # Update column with final (promoted) data
    self.{{data_column.id}} = {{name.id}}_attacher.column_data
    @_shrine_{{name.id}}_changed = false
    # We need to update the record with the new data column value
    # but avoid infinite loop - just update the column directly
    _shrine_persist_{{name.id}}_data
  end

  # Destroy the attachment when the record is destroyed
  @[Ralph::Callbacks::AfterDestroy]
  def _shrine_destroy_{{name.id}}
    {{name.id}}_attacher.destroy_attached
  end

  # Internal: Persist just the attachment data column without full save
  private def _shrine_persist_{{name.id}}_data
    return if new_record?
    data = self.{{data_column.id}}
    pk = primary_key_value
    return unless pk
    sql = "UPDATE \"#{self.class.table_name}\" SET \"{{data_column.id}}\" = ? WHERE \"#{self.class.primary_key}\" = ?"
    Ralph.database.execute(sql, args: [data, pk])
  end
end
