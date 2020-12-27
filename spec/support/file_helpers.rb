# frozen_string_literal: true

module AutoDeletingTempfile
  def with_auto_deleting_tempfile(tempfile_prefix, tempfile_suffix)
    file = Tempfile.new([tempfile_prefix, tempfile_suffix])
    yield file
  ensure
    file.close
    file.unlink
  end
end
