require 'spec_helper'

describe 'PhraseApp for Android' do

  let (:client_params) do
    {
        path: 'spec/files/src'
    }
  end

  it 'detects locales' do
    client = PhraseApp::Android::PhraseAppClient.new client_params
    expect(client.locales).to match_array(%w(sw ru))
  end

  it 'detects missing translations' do
    client = PhraseApp::Android::MissingTranslations.new client_params
    expect(client.find('sw')).to be_empty

    values = client.find('ru')
    expect(values).not_to be_empty
    expect(values.size).to eq(2)
    expect(values[0].name).to eq('string')
    expect(values[0].attr('name')).to eq('ok')
    expect(values[1].name).to eq('string-array')
    expect(values[1].attr('name')).to eq('languages')
    expect(values[1].element_children.size).to eq(2)
  end

  it 'builds upload file' do
    client = PhraseApp::Android::Upload.new client_params
    file = client.build_upload_file
    doc = client.read_xml_file file.path
    file.unlink

    expect(doc).to_not be_nil
    values = doc.at('//resources').element_children
    expect(values.size).to eq(8)
    expectations = [
        %w(string application_name проверка),
        %w(string formatted %s\ это\ %d),
        %w(string-array codes 1),
        %w(string application_name SW\ App),
        %w(string ok Sawa),
        %w(string formatted %s\ -\ %\ d),
        %w(string-array languages 2),
        %w(string-array codes 1)
    ]
    expectations.each_with_index do |e, idx|
      expect(values[idx].name).to eq(e[0])
      expect(values[idx].attr('name')).to eq(e[1])
      if e[0] == 'string-array'
        expect(values[idx].element_children.size).to eq(e[2].to_i)
      else
        expect(values[idx].text).to eq(e[2])
      end
    end
  end

  it 'uploads file' do
    client = PhraseApp::Android::Upload.new client_params
    allow(client.client).to receive(:upload_create) { 'uploaded' }
    expect(client.perform).to eq('uploaded')
  end

  it 'downloads translations' do
    allow_any_instance_of(PhraseApp::Android::FileFormatter).to receive(:apply).and_return(false)

    client = PhraseApp::Android::MissingTranslations.new client_params
    allow(client).to receive(:write_to_file) { true }
    allow(client.client).to receive(:locale_download) do
      <<JSON
<?xml version="1.0" encoding="UTF-8"?>
<resources>
    <string name="application_name">проверка!</string>
    <string name="ok">хорошо</string>
    <string name="ok2">ok2</string>
    <string-array name="languages">
        <item>Английский</item>
        <item>Свахили</item>
    </string-array>
    <string-array name="codes">
      <item>RUS</item>
    </string-array>
</resources>
JSON
    end

    pulled = client.pull_locale('ru')
    expect(pulled[:strings][:added]).to eq(1)
    expect(pulled[:strings][:updated]).to eq(1)
    expect(pulled[:arrays][:added]).to eq(1)
    expect(pulled[:arrays][:updated]).to eq(1)
  end

  it 'should check string formats' do
    client = PhraseApp::Android::FormatCheck.new client_params
    expect(client.perform).to eq(1)
    expect(client.perform_for_locale('ru')).to eq(0)
    expect(client.perform_for_locale('sw')).to eq(1)
  end

  it 'should format files nicely' do
    formatter = PhraseApp::Android::FileFormatter.new client_params
    doc = formatter.read_locale_file 'strings', nil
    expect(doc).not_to be_nil

    formatted = Nokogiri::XML::Document.parse formatter.apply_to_xml_doc(doc)
    expect(formatted).not_to be_nil
    expect(formatted.at('//resources').element_children.map{ |e| e.attr('name') }).to eq(%w(application_name formatted ok version))
  end

end
