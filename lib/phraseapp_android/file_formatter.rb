require_relative './phrase_app_client'

class PhraseApp::Android::FileFormatter < PhraseApp::Android::PhraseAppClient

  def apply(file_name, locale)
    doc = read_locale_file file_name, locale
    formatted = apply_to_xml_doc doc
    File.write locale_file_name(file_name, locale), formatted
  end

  def apply_to_xml_doc(doc)
    data = {}
    ignore_keys = []

    match_elements doc, 'integer-array', data, ignore_keys
    match_elements doc, 'string-array', data, ignore_keys
    match_elements doc, 'string', data, ignore_keys

    last_name = nil
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.resources('xmlns:tools' => 'http://schemas.android.com/tools') do
        data.keys.sort.each do |k|
          name = k.split('_').first.to_s

          if last_name != name
            xml.comment " #{name} * "
            last_name = name
          end

          attrs = {name: k}
          attrs['tools:ignore'] = 'MissingTranslation' if ignore_keys.include? k

          xml.send data[k][:name], attrs do
            if data[k][:name].end_with?('array')
              data[k][:value].each do |t|
                xml.item t
              end
            else
              xml.text data[k][:value]
            end
          end
        end
      end
    end

    builder.to_xml indent: 4
  end

  def apply_to_all_files
    count = 0
    ([nil] + locales).each do |locale|
      apply 'strings', locale
      apply 'arrays', locale
      count += 2
    end
    puts "#{count} files were reformatted.".green
  end

  private

  def match_elements(doc, node_name, data, ignore_keys)
    doc.at('//resources').search(node_name).each do |string|
      data[string.attr('name')] = {name: string.name, value: node_name.end_with?('array') ? string.search('item').map(&:text) : string.text}
      ignore_keys << string.attr('name') if string.attr('tools:ignore')
    end
  end

end