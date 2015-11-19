require_relative './phrase_app_client'

class PhraseApp::Android::MissingTranslations < PhraseApp::Android::PhraseAppClient

  def list
    count = 0
    locales.each do |locale|
      missing = find locale
      if missing.size > 0
        puts "Missing translations for #{locale.upcase} locale:".red
        missing.each { |s| puts s.to_s.yellow }
        count += missing.size
      end
    end
    puts 'No missing translations found.'.green if count == 0
  end

  def find(locale)
    list = []

    default_strings, default_arrays = load_locale_files nil
    localized_strings, localized_arrays = load_locale_files locale

    default_strings.each do |name, el|
      list << el unless localized_strings.has_key?(name)
    end

    default_arrays.each do |name, el|
      list << el if !localized_arrays.has_key?(name) || el.search('item').size != localized_arrays[name].search('item').size
    end

    list
  end

  def pull
    locales.each do |locale|
      pull_locale locale
    end
  end

  def pull_locale(locale)
    stats = {
        strings: {added: 0, updated: 0},
        arrays: {added: 0, updated: 0}
    }

    default_strings = doc_to_hash read_locale_file('strings', nil)
    default_arrays = doc_to_hash read_locale_file('arrays', nil)
    default = default_strings.merge default_arrays

    strings = doc_to_hash read_locale_file('strings', locale)
    arrays = doc_to_hash read_locale_file('arrays', locale)
    current = strings.merge arrays

    params = PhraseApp::RequestParams::LocaleDownloadParams.new file_format: 'xml'
    doc = Nokogiri::XML client.locale_download(project_id, locale, params)
    recent = doc_to_hash doc

    merge_translations default, current, recent, :strings, stats, locale
    merge_translations default, current, recent, :arrays, stats, locale

    formatter = PhraseApp::Android::FileFormatter.new

    if stats[:strings][:added] + stats[:strings][:updated] > 0
      updated_strings = formatter.apply_to_xml_doc hash_to_doc(current[:strings])
      write_to_file locale_file_name('strings', locale), updated_strings
    end

    if stats[:arrays][:added] + stats[:arrays][:updated] > 0
      updated_arrays = formatter.apply_to_xml_doc hash_to_doc(current[:arrays])
      write_to_file locale_file_name('arrays', locale), updated_arrays
    end

    added = stats[:strings][:added] + stats[:arrays][:added]
    updated = stats[:strings][:updated] + stats[:arrays][:updated]

    if added + updated > 0
      puts "#{added + updated} keys were updated for #{locale} locale!".green
    else
      puts "no keys were updated for #{locale} locale.".yellow
    end

    stats
  end

  private

  def load_locale_files(locale)
    strings = {}
    arrays = {}

    %w(strings arrays).each do |file|
      doc = read_locale_file(file, locale).at('//resources')
      doc.search('string').each do |str|
        strings[str.attr('name')] = str unless str.attr('tools:ignore')
      end
      doc.search('string-array').each do |array|
        arrays[array.attr('name')] = array unless array.attr('tools:ignore')
      end
    end

    [strings, arrays]
  end

  def doc_to_hash(doc)
    result = {strings: {}, arrays: {}}
    doc.at('//resources').element_children.each do |el|
      if el.name == 'string'
        result[:strings][el.attr('name')] = el.text
      elsif el.name == 'string-array'
        result[:arrays][el.attr('name')] = el.element_children.map { |c| c.text }
      end
    end
    result.reject { |k, v| v.empty? }
  end

  def merge_translations(default, current, updated, key, stats, locale)
    updated[key].each do |name, values|
      if default[key][name]
        current[key] ||= {}
        current_value = current[key][name]
        # auto prettify string resources
        values = clean_up_string values if values.is_a? String
        values = values.map { |item| clean_up_string item } if values.is_a? Array

        if current_value
          if values != current_value
            if values.is_a?(Array) && values.size != current_value.size
              puts "MERGE CONFLICT for #{name} array in #{locale} locale!\n#{current_value.inspect} vs #{values.inspect}".red
            else
              current[key][name] = values
              stats[key][:updated] += 1
            end
          end
        else
          current[key][name] = values
          stats[key][:added] += 1
        end
      end
    end
  end

  def clean_up_string(value)
    value.strip.gsub '...', '…'
  end

  def hash_to_doc(source)
    doc = Nokogiri::XML::Document.new
    doc.encoding = 'utf-8'
    res = doc.create_element 'resources', 'xmlns:tools' => 'http://schemas.android.com/tools'
    doc.add_child res

    source.each do |name, value|
      if value.is_a? Array
        str = Nokogiri::XML::Node.new 'string-array', res
        str['name'] = name
        value.each do |text_item|
          item = Nokogiri::XML::Node.new 'item', str
          item.content = text_item
          str.add_child item
        end
        res.add_child str
      else
        str = Nokogiri::XML::Node.new 'string', res
        str['name'] = name
        str.content = value
        res.add_child str
      end
    end
    doc
  end

end