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
    strings_updated = 0
    arrays_updated = 0
    missing = find locale
    if missing.size > 0
      strings = read_locale_file 'strings', locale
      arrays = read_locale_file 'arrays', locale

      params = PhraseApp::RequestParams::LocaleDownloadParams.new file_format: 'xml'
      doc = Nokogiri::XML client.locale_download(project_id, locale, params)

      missing.each do |el|
        name = el.attr 'name'
        translated = doc.at('//resources').search("#{el.name}[@name=#{name}]").first
        if translated
          if el.name == 'string'
            str = Nokogiri::XML::Node.new 'string', strings
            str['name'] = name
            str.content = translated.text
            strings.at('//resources').children.last.after str
            strings_updated += 1
          elsif el.name == 'string-array'
            str = Nokogiri::XML::Node.new 'string-array', arrays
            str['name'] = name
            translated.element_children.each do |child|
              item = Nokogiri::XML::Node.new 'item', arrays
              item.content = child.text
              str.add_child item
            end
            arrays.at('//resources').children.last.after str
            arrays_updated += 1
          end
        end
      end

      if strings_updated + arrays_updated > 0
        PhraseApp::Android::FileFormatter.new.apply('strings', locale) if strings_updated > 0
        PhraseApp::Android::FileFormatter.new.apply('arrays', locale) if arrays_updated > 0
        puts "#{strings_updated + arrays_updated} translation keys were updated.".green
      else
        puts 'no keys were updated.'.yellow
      end
    end

    [strings_updated, arrays_updated]
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

end