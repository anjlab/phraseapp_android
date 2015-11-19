require_relative './phrase_app_client'

class PhraseApp::Android::FormatCheck < PhraseApp::Android::PhraseAppClient

  attr_accessor :keys

  def initialize(options = {})
    super(options)

    self.keys = xml_strings_to_hash 'strings', nil
  end

  def perform
    count = locales.map { |l| perform_for_locale(l) }.reduce(:+)
    puts 'All texts are ok.'.green
    count
  end

  def perform_for_locale(locale)
    data = xml_strings_to_hash 'strings', locale
    count = 0

    keys.each do |name, value|
      formatters = value.scan /(%[\d$a-z]+)/i
      count += 1 if formatters && !check_formatters(locale, data, name, formatters)
    end

    count
  end

  private

  def xml_strings_to_hash(file_name, locale)
    string_keys = {}
    read_locale_file(file_name, locale).at('//resources').search('string').each do |string|
      string_keys[string.attr('name')] = string.text
    end
    string_keys
  end

  def check_formatters(locale, locale_data, name, sample_formatters)
    localized_key = locale_data[name]
    if localized_key
      sw_formatters = localized_key.scan /(%[\d$a-z]+)/i
      if sample_formatters.sort != sw_formatters.sort
        puts ('%s: Arguments mismatch for %s' % [locale, name]).red
        return false
      end
    end
    true
  end

end