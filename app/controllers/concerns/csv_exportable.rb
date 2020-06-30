#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module CsvExportable
  def send_csv(csv_data, filename)
    csv_file_export_header(filename)
    send_data(csv_data, filename: filename, type: 'text/csv; charset=utf-8; header=present')
  end

  def csv_file_export_header(filename)
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers['Content-type'] = 'text/plain'
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = '0'
    else
      headers['Content-Type'] ||= 'text/csv'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    end
    headers['Last-Modified'] = Time.zone.now.httpdate
  end
end
