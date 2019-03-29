module Derivativo::PdfDerivatives
	extend ActiveSupport::Concern

	def derivative_proc_for_output_path(out_path)
		Proc.new do |in_path|
			office_convert(in_path, out_path, DERIVATIVO['soffice_path'], 'pdf:writer_pdf_Export')
		end
	end

	def office_convert(in_path, out_path, soffice_path, office_export_format)
		soffice_path ||= soffice_path || which('soffice') || which('soffice.bin')

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

		# Copy our custom office settings to office_temp_homedir
		soffice_home_userdir = File.join(office_temp_homedir, "user")
		FileUtils.mkdir_p(soffice_home_userdir)

		set_soffice_pdf_compression_level(soffice_home_userdir, 85) # default level

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
		system(conversion_command)

		# The office conversion process always keeps the original name of the file and replaces
		# the extension with 'pdf', so we'll need to predict the tmp outpath and move it after.
		expected_conversion_outpath = File.join(tmp_outdir, File.basename(in_path).sub(/(.+)\..+$/, '\1.pdf'))

		if File.exists?(expected_conversion_outpath)
			file_size_in_mb = (File.size(expected_conversion_outpath)/1000000.0).to_i
			# If the new access copy file is larger than 30 MB, we need to re-encode that new
			# access copy at a lower compression level. We don't want to re-use the original copy
			# because we don't know what level of compression has been applied its content/embedded images.
			# The access copy we first generated has a standard degree of compression that we know,
			# so we can base further compression on that baseline.
			if file_size_in_mb > 30
				integer_percentage = percentage_compression_for_file_size(file_size_in_mb)
				set_soffice_pdf_compression_level(soffice_home_userdir, integer_percentage) # default level

				# Move file at expected_conversion_outpath to new in_path (and update in_path) so we can re-export to that same original outpath
				recode_in_path = File.join(File.dirname(expected_conversion_outpath), 'temp-' + File.basename(expected_conversion_outpath))
				FileUtils.mv(expected_conversion_outpath, recode_in_path)

				# Do the conversion, updating the in_path
				in_path = recode_in_path
				system(conversion_command)
				# After successful conversion, delete the recode_in_path file, since it was temporary
				File.delete(recode_in_path)
			end
		end

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

	# Checks the user's $PATH for the given program
	def which(program)
	  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
	  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
	    exts.each do |ext|
	      exe = File.join(path, "#{program}#{ext}")
	      return exe if File.executable? exe
	    end
	  end

	  nil
	end

	def set_soffice_pdf_compression_level(soffice_home_userdir, compression_integer)
		settings_file_content = IO.read(Rails.root.join('config', 'soffice', 'registrymodifications-custom-compression.xcu'))
		settings_file_content.gsub!('_COMPRESSION_VALUE_', compression_integer.to_s)
		IO.write(File.join(soffice_home_userdir, 'registrymodifications.xcu'), settings_file_content)
	end

	def percentage_compression_for_file_size(file_size_in_mb)
		return 10 if file_size_in_mb > 1000
		return 100 if file_size_in_mb < 30
		# This formula seems to give decent results, but might need more adjustments in the future.
		((1/Math.log(file_size_in_mb, 10))**2 * 100).to_i
	end
end
