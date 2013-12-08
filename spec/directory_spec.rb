require 'spec_helper'

describe 'DirectoryTag' do

  let(:doc) { Nokogiri::HTML::DocumentFragment.parse generated_html }

  let(:generated_html) {
    info = { :filters => [Jekyll::Filters], :registers => { :site => site } }
    converter = site.converters.find { |c| c.class == Jekyll::Converters::Markdown }
    result = Liquid::Template.parse(post).render({}, info)
    converter.convert(result)
  }

  let(:site)            { Jekyll::Site.new(configuration) }

  let(:configuration)   { Jekyll::Configuration::DEFAULTS.deep_merge(
    'source' => source_dir,
    'plugins' => plugins_dir,
    'markdown' => 'rdiscount' # marku has trouble with img titles
  ) }

  let(:post) { <<-post }
{% directory #{parameters} %}
#{content}
{% enddirectory %}
post


  let(:parameters) { "path: images" }

  before do
    Dir.chdir source_dir
    FileUtils.mkdir_p 'images'
  end

  after { FileUtils.rm_rf   'images' }

  describe "parameters" do
    before do
      FileUtils.touch   'images/2008-08-08-alpha-team.jpg'
      FileUtils.touch   'images/2009-09-09-bravo-squad.jpg'
      FileUtils.touch   'images/2010-10-10-charlie-company.jpg'
    end

    let(:content) { %q* - {{ file.date | date: "%F" }} * }
    let(:dates)   { %w(2008-08-08 2009-09-09 2010-10-10) }

    it "should be sorted by date" do
      doc.css('li').map(&:text).should == dates
    end

    context "with reverse: true" do
      let(:parameters) { "path: images reverse: true" }

      it "should be sorted by date" do
        doc.css('li').map(&:text).should == dates.reverse
      end
    end

    context "with an exclude regex" do
      let(:parameters) { "path: images exclude: c.ar" }

      it "should be sorted by date" do
        doc.css('li').map(&:text).should == %w(2008-08-08 2009-09-09)
      end
    end
  end

  describe "directory with nested dirs" do
    let(:content) { %q* - {{ file.name}} * }

    before do
      FileUtils.mkdir_p 'images/icons'
      FileUtils.mkdir_p 'images/other'
      FileUtils.mkdir_p 'images/pictures'
    end

    it "should show items without extensions" do
      doc.css('li').map(&:text).should == %w(icons other pictures)
    end

  end

  describe "directory check" do
    let(:parameters) { "path: ../ " }
    let(:content) { %q* - {{ file.name}} * }

    it "should throw an expetion when accessing to dir out of project root" do
      target_dir = File.expand_path File.join(source_dir, "../")
      doc.css('p').map(&:text)[0].should == "Liquid error: Listed directory '#{target_dir}' cannot be out of jekyll root"
    end
  end

  describe "file object" do
    let(:content)    { %q* ![{{ file.slug }}]({{file.url}} "Taken on {{ file.date | date: "%d %B %Y" }}") * }

    before do
      FileUtils.touch   'images/2008-08-08-alpha-team.jpg'
    end


    it "should have the alt, src, and title" do
      imgs = doc.css('img')
      imgs.should have(1).image

      img = imgs.first
      img[:alt].should == "alpha-team"
      img[:src].should == "/images/2008-08-08-alpha-team.jpg"
      img[:title].should == "Taken on 08 August 2008"
    end
  end

end

