require "libreconv"

module Derivativo::PdfDerivatives
	extend ActiveSupport::Concern

	def derivative_proc_for_output_path(out_path)
		Proc.new do |in_path|
			# get the path to soffice; this can be nil if soffice is on the $PATH
			soffice_path = DERIVATIVO['soffice_path']
			Libreconv.convert(in_path, out_path, soffice_path, 'pdf:writer_pdf_Export')
		end
	end
end