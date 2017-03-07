require "rails_helper"

describe AsciidocChapterProcessor do
  let(:book) { create_asciidoc_book! }
  let(:chapter) { book.chapters.create(title: "Test Chapter") }
  let(:element) do
    build_chapter_element <<-HTML
      #{content}
    HTML
  end
  before { subject.perform(book.id, chapter.id, element.to_s) }

  def build_chapter_element(tags)
    Nokogiri::HTML.parse(<<-HTML
      <div class="sect1">
        #{tags}
      </div>
    HTML
    ).css(".sect1")
  end

  context "h2" do
    let(:content) { %Q{<h2 id="_chapter_1">1. Chapter 1</h2>} }

    # Chapter title has already been handled
    it "adds no element to the chapter" do
      expect(chapter.elements.count).to eq(0)
    end
  end

  context "table" do
    let(:content) do
      <<-HTML.strip
      <table>
        <tr>
          <td>A table.</td>
        </tr>
      </table>
      HTML
    end

    it "adds the table element to the chapter" do
      element = chapter.elements.find_by(tag: "table")
      expect(element.content).to eq(content)
    end
  end

  context "div.paragraph" do
    let(:content) { %Q{<div class="paragraph"><p>Simple paragraph</p></div>} }

    it "adds a h2 element to the chapter" do
      element = chapter.elements.find_by(tag: "p")
      expect(element.content).to eq("<p>Simple paragraph</p>")
    end
  end

  context "div.listingblock" do
    let(:content) do
      <<-HTML.strip
        <div class="listingblock">
        <div class="title">book.rb</div>
        <div class="content">
        <pre class="highlight"><code class="language-ruby" data-lang="ruby">class Book
          attr_reader :title

          def initialize(title)
            @title = title
          end
        end</code></pre>
        </div>
      </div>
      HTML
    end

    it "adds the listingblock element to the chapter" do
      element = chapter.elements.find_by(tag: "div")
      expect(element.content).to eq(content)
    end
  end

  context "div.imageblock" do
    let(:content) do
      <<-HTML.strip
      <div class="imageblock">
        <div class="content">
          <img src="ch01/images/welcome_aboard.png" alt="welcome aboard">
        </div>
        <div class="title">
          Figure 1. Welcome aboard!
        </div>
      </div>
      HTML
    end

    it "adds the imageblock element to the chapter" do
      element = chapter.elements.find_by(tag: "img")
      expect(element.content).to eq("ch01/images/welcome_aboard.png")

      image = chapter.images.last
      expect(image.image_file_name).to eq("welcome_aboard.png")
      expect(image.position).to eq(1)
      expect(image.caption).to eq("Welcome aboard!")
    end
  end

  context "div.sect2 w/ h3 & div.para" do
    let(:content) do
      <<-HTML
      <div class="sect2">
        <h3>Sect2 title</h3>
        <div class="paragraph">
          <p>Simple para inside of a sect2</p>
        </div>
      </div>
      HTML
    end

    it "adds the h3 and para elements to the chapter" do
      h3_element = chapter.elements.find_by(tag: "h2")
      expect(h3_element.content).to eq("<h2>Sect2 title</h2>")


      para_element = chapter.elements.find_by(tag: "p")
      expect(para_element.content).to eq("<p>Simple para inside of a sect2</p>")
    end
  end

  context "div.sect3 w/ h4 & div.para" do
    let(:content) do
      <<-HTML
      <div class="sect3">
        <h4>Sect3 title</h4>
        <div class="paragraph">
          <p>Simple para inside of a sect3</p>
        </div>
      </div>
      HTML
    end

    it "adds the h3 and para elements to the chapter" do
      h3_element = chapter.elements.find_by(tag: "h3")
      expect(h3_element.content).to eq("<h3>Sect3 title</h3>")


      para_element = chapter.elements.find_by(tag: "p")
      expect(para_element.content).to eq("<p>Simple para inside of a sect3</p>")
    end
  end

  context "div.sect4 w/ h5 & div.para" do
    let(:content) do
      <<-HTML
      <div class="sect4">
        <h5>Sect4 title</h5>
        <div class="paragraph">
          <p>Simple para inside of a sect4</p>
        </div>
      </div>
      HTML
    end

    it "adds h4 and para elements to the chapter" do
      h4_element = chapter.elements.find_by(tag: "h4")
      expect(h4_element.content).to eq("<h4>Sect4 title</h4>")

      para_element = chapter.elements.find_by(tag: "p")
      expect(para_element.content).to eq("<p>Simple para inside of a sect4</p>")
    end
  end

  context "div.admonitionblock" do
    let(:content) do
      <<-HTML.strip
      <div class="admonitionblock note">
        <table>
          <tr>
            <td class="icon">
              <div class="title">Note</div>
            </td>
            <td class="content">
              <div class="title">This is a note</div>
              <div class="paragraph">
                <p>Notes stand out different from the text.</p>
              </div>

              <div class="listingblock">
                <div class="content">
                  <pre>$ rails new rails
                  Invalid application name rails, constant Rails is already in use.
                  Please choose another application name.
                  $ rails new test
                  Invalid application name test. Please give a name which does not match one of
                  the reserved rails words.</pre>
                </div>
              </div>
            </td>
          </tr>
        </table>
      </div>
      HTML
    end

    it "adds the admonitionblock element to the chapter" do
      element = chapter.elements.find_by(tag: "div")
      expected =
      <<-HTML.strip
        <div class="admonitionblock note">
          <div class="title">This is a note</div>
          <div class="paragraph">
            <p>Notes stand out different from the text.</p>
          </div>

          <div class="listingblock">
            <div class="content">
              <pre>$ rails new rails
              Invalid application name rails, constant Rails is already in use.
              Please choose another application name.
              $ rails new test
              Invalid application name test. Please give a name which does not match one of
              the reserved rails words.</pre>
            </div>
          </div>
        </div>
      HTML
      expect(element.content.gsub(/^\s+/, '')).to eq(expected.gsub(/^\s+/, ''))
    end
  end

  context "div.ulist" do
    let(:content) do
      <<-HTML.strip
      <div class="ulist">
        <ul>
          <li><p>Item 1</p></li>
          <li><p>Item 2</p></li>
          <li><p>Item 3</p></li>
        </ul>
      </div>
      HTML
    end

    it "adds the ul element to the chapter" do
      element = chapter.elements.find_by(tag: "ul")
      expect(element.content).to eq(<<-HTML.strip
        <ul>
          <li><p>Item 1</p></li>
          <li><p>Item 2</p></li>
          <li><p>Item 3</p></li>
        </ul>
      HTML
      )
    end
  end

  context "div.olist" do
    let(:content) do
      <<-HTML.strip
      <div class="olist arabic">
        <ol>
          <li><p>Item 1</p></li>
          <li><p>Item 2</p></li>
          <li><p>Item 3</p></li>
        </ol>
      </div>
      HTML
    end

    it "adds the ol element to the chapter" do
      element = chapter.elements.find_by(tag: "ol")
      expect(element.content).to eq(<<-HTML.strip
        <ol>
          <li><p>Item 1</p></li>
          <li><p>Item 2</p></li>
          <li><p>Item 3</p></li>
        </ol>
      HTML
      )
    end
  end

  context "div.quoteblock" do
    let(:content) do
      <<-HTML.strip
      <div class="quoteblock">
        <blockquote>
          <div class="paragraph">
            <p>May the force be with you.</p>
          </div>
        </blockquote>
        <div class="attribution">
          — Gandalf
        </div>
      </div>
      HTML
    end

    it "adds the quoteblock element to the chapter" do
      element = chapter.elements.find_by(tag: "div")
      expect(element.content).to eq(content)
    end
  end
end
