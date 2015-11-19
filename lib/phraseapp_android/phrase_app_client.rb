require 'phraseapp-ruby'
require 'nokogiri'
require 'colorize'

module PhraseApp

  module Android

    class PhraseAppClient

      attr_accessor :client, :project_id, :locale_files, :locales, :sub_path

      def initialize(options = {})
        credentials = PhraseApp::Auth::Credentials.new token: (options[:token] || ENV['PHRASE_ACCESS_TOKEN'])
        self.client = PhraseApp::Client.new credentials
        self.project_id = options[:project_id] || ENV['PHRASE_PROJECT_ID']
        self.sub_path = options[:path]
        find_locales
      end

      def read_xml_file(file_name)
        if file_name
          f = File.open file_name
          doc = Nokogiri::XML f
          f.close
          doc
        end
      end

      def read_locale_file(file_name, locale)
        read_xml_file locale_file_name(file_name, locale)
      end

      def locale_file_name(file_name, locale)
        locale = '-' + locale unless locale.nil?
        locale_files.find { |f| f.end_with?("values#{locale}/#{file_name}.xml") }
      end

      protected

      def find_locales
        self.locale_files = Dir.glob("#{sub_path}**/main/res/values*/{strings,arrays}.xml")
        self.locales = locale_files
                           .map { |file| file.match(/res\/values[-]*([a-z]+)?\//i)[1] }
                           .compact
                           .uniq
      end

      def write_xml_to_file(path, doc)
        write_to_file path, doc.to_xml(ident: 4)
      end

      def write_to_file(path, contents)
        File.open path, 'w' do |f|
          f.write contents
        end
      end

    end

  end

end