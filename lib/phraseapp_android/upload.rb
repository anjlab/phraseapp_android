require_relative './phrase_app_client'
require 'tempfile'

class PhraseApp::Android::Upload < PhraseApp::Android::PhraseAppClient

  def perform(locale = 'en')
    file = build_upload_file

    params = PhraseApp::RequestParams::UploadParams.new file: file.path, file_format: 'xml', locale_id: locale
    upload = client.upload_create project_id, params

    puts 'Successfully uploaded.'.green
    file.unlink

    upload
  end

  def build_upload_file
    tmp = Tempfile.new %w(translations .xml)

    doc = Nokogiri::XML::Document.new
    doc.encoding = 'utf-8'
    res = doc.create_element 'resources', 'xmlns:tools' => 'http://schemas.android.com/tools'
    doc.add_child res

    %w(strings arrays).each do |file|
      read_locale_file(file, nil).at('//resources').element_children.each do |el|
        res.add_child(el) if el.attr('tools:ignore').nil?
      end
    end

    tmp.write doc.to_xml(indent: 4)
    tmp.close
    tmp
  end

end