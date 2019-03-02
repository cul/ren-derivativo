module Derivativo::PdfDerivatives
	extend ActiveSupport::Concern

	def derivative_proc_for_output_path(out_path)
		Proc.new do |in_path|
			office_convert(in_path, out_path, DERIVATIVO['soffice_path'], 'pdf:writer_pdf_Export')
		end
	end

	def office_convert(in_path, out_path, soffice_path, office_export_format)
		# Create a unique, temporary home dir for this office process so we can run multiple
		# conversion jobs independently. If two conversion processes use the same home dir,
		# the first process will block the second one.
		office_temp_homedir = "/tmp/soffice-dir-threadid-#{Thread.current.object_id}"
		FileUtils.mkdir_p(office_temp_homedir)

		# Create tmp_outdir inside the target out_dir so that we are writing to the
		# target destination volume, but don't ever accidentally overwrite a same-name
		# file in the out_dir (e.g. if the out_dir already contained both
		# 'file.docx' and 'file.pdf' and we wanted to write a temp file called 'file.pdf'
		# temporarily before renaming it to 'file2.pdf'.
		tmp_outdir = File.join(File.dirname(out_path), 'soffice-tmp')

		conversion_command = [
			soffice_path,
			"-env:UserInstallation=file://#{office_temp_homedir}",
			'--invisible',
			'--headless',
			'--convert-to',
			office_export_format,
			'--outdir',
			Shellwords.escape(tmp_outdir),
			Shellwords.escape(in_path)
		].join(' ')

		# The office conversion process always keeps the original name of the file and replaces
		# the extension with 'pdf', so we'll need to predict the tmp outpath and move it after.
		expected_conversion_outpath = File.join(tmp_outdir, File.basename(in_path).sub(/(.+)\..+$/, '\1.pdf'))

		system(conversion_command)

		if (success = File.exists?(expected_conversion_outpath))
			# Move the file to the correct out_path
			FileUtils.mv(expected_conversion_outpath, out_path)
		else
			Rails.logger.error('Failed to convert document to PDF using command: ' + conversion_command)
		end

		# Clean up tmp_outdir and office_temp_homedir when we're done with the conversion
		FileUtils.rm_rf(tmp_outdir)
		FileUtils.rm_rf(office_temp_homedir)

		# Return succes value (true if successful, false if failure)
		success
	end
end
