# Copyright (c) 2002-2018 Minero Aoki, Kenshi Muto
#
# This program is free software.
# You can distribute or modify this program under the terms of
# the GNU LGPL, Lesser General Public License version 2.1.
#

require 'review/book/index'
require 'review/exception'
require 'review/textutils'
require 'review/compiler'
require 'review/sec_counter'
require 'stringio'
require 'fileutils'
require 'tempfile'

## IndexBuilder
#
#
#

# ChapterIndex
# ListIndex
# TableIndex
# EquationIndex
# FootnoteIndex
# ImageIndex
# IconIndex
# BibpaperIndex
# NumberlessImageIndex
# IndepImageIndex
# HeadlineIndex
# ColumnIndex
#
# ImageIndex::Item
# NumberlessImageIndex::Item
# IndepImageIndex::Item

module ReVIEW
  class IndexBuilder
    CAPTION_TITLES = %w[note memo tip info warning important caution notice box].freeze

    attr_accessor :doc_status

    def initialize(strict = false, *args)
      @strict = strict
      @index_list = []
      builder_init(*args)
    end

    def builder_init(*args)
    end
    private :builder_init

    def bind(compiler, chapter, location)
      @compiler = compiler
      @chapter = chapter
      @location = location
      if @chapter.present?
        @book = @chapter.book
      end
      builder_init_file
    end

    def builder_init_file
      @sec_counter = SecCounter.new(5, @chapter)

      @list_index = [] ## in ReVIEW::Book::Chapter
      @table_index = []
      @equation_index = []
      @footnote_index = []
      @image_index = []
      @icon_index = []
      @numberless_image_index = []
      @indepimage_index = []
      @headline_index = []
      @column_index = []
      @chapter_index = []  ## in ReVIEW::Book::Base
      @bibpaper_index = [] ## in ReVIEW::Book:Compilable

      @doc_status = {}
    end
    private :builder_init_file

    def result
      # XXX
    end

    def target_name
      'index'
    end

    def headline(level, _label, caption)
      prefix, _anchor = headline_prefix(level)

      @headline_index << %Q(#{prefix}#{compile_inline(caption)})
    end

    def headline_prefix(level)
      @sec_counter.inc(level)
      anchor = @sec_counter.anchor(level)
      prefix = @sec_counter.prefix(level, @book.config['secnolevel'])
      [prefix, anchor]
    end
    private :headline_prefix

    def nonum_begin(level, label, caption)
    end

    def column_begin(_level, label, caption)
      item = ReVIEW::Book::ColumnIndex::Item.new(label, @list_index.size + 1, caption)
      @column_index << item
    end

    def column_end(_level)
    end

    def xcolumn_begin(level, label, caption)
    end

    def xcolumn_end(_level)
    end

    def sup_begin(level, label, caption)
    end

    def sup_end(_level)
    end

    def ul_begin
    end

    def ul_item_begin(lines)
    end

    def ul_item_end
    end

    def ul_end
    end

    def ol_begin
    end

    def ol_item(lines, _num)
    end

    def ol_end
    end

    def dl_begin
    end

    def dt(line)
    end

    def dd(lines)
    end

    def dl_end
    end

    def paragraph(lines)
    end

    def parasep
      puts '<br />'
    end

    def nofunc_text(_str)
      ''
    end

    def read(lines)
      blocked_lines = split_paragraph(lines)
      puts %Q(<div class="lead">\n#{blocked_lines.join("\n")}\n</div>)
    end

    def list(_lines, id, _caption, _lang = nil)
      item = ReVIEW::Book::ListIndex::Item.new(id, @list_index.size + 1)
      @list_index << item
    end

    def listnum(_lines, id, _caption, _lang = nil)
      item = ReVIEW::Book::ListIndex::Item.new(id, @list_index.size + 1)
      @list_index << item
    end

    def emlist(lines, caption = nil, lang = nil)
    end

    def emlistnum(lines, caption = nil, lang = nil)
    end

    def cmd(lines, caption = nil)
    end

    def source(lines, caption, lang = nil)
    end

    def image(_lines, id, caption, _metric = nil)
      item = ReVIEW::Book::ImageIndex::Item.new(id, @image_index.size + 1, caption)
      @image_index << item
    end

    def table(_lines, id = nil, _caption = nil)
      item = ReVIEW::Book::TableIndex::Item.new(id, @table_index.size + 1)
      @table_index << item
    end

    def emtable(_lines, _caption = nil)
      # item = ReVIEW::Book::TableIndex::Item.new(id, @table_index.size + 1)
      # @table_index << item
    end

    def comment(lines, comment = nil)
    end

    def imgtable(_lines, id, _caption = nil, _metric = nil)
      item = ReVIEW::Book::TableIndex::Item.new(id, @table_index.size + 1)
      @table_index << item
    end

    def footnote(id, _str)
      item = ReVIEW::Book::FootnoteIndex::Item.new(id, @footnote_index.size + 1)
      @footnote_index << item
    end

    def indepimage(_lines, id, _caption = '', _metric = nil)
      item = ReVIEW::Book::IndepImageIndex::Item.new(id, @indepimage_index.size + 1)
      @indepimage_index << item
    end

    def blankline
    end

    def flushright(lines)
    end

    def pagebreak
    end

    def bpo(lines)
    end

    def noindent
    end

    def compile_inline(s)
      @compiler.text(s)
    end

    def inline_chapref(_id)
      ''
    end

    def inline_chap(_id)
      ''
    end

    def inline_title(_id)
      ''
    end

    def inline_list(_id)
      ''
    end

    def inline_img(_id)
      ''
    end

    def inline_imgref(_id)
      ''
    end

    def inline_table(_id)
      ''
    end

    def inline_eq(_id)
      ''
    end

    def inline_fn(_id)
      ''
    end

    def inline_bou(str)
      str
    end

    def inline_ruby(arg)
      base, *_ruby = *arg.scan(/(?:(?:(?:\\\\)*\\,)|[^,\\]+)+/)
      if base
        base.gsub(/\\,/, ',')
      else
        ''
      end
    end

    def inline_kw(arg)
      word, _alt = *arg.split(',', 2)
      word
    end

    def inline_href(arg)
      _url, label = *arg.scan(/(?:(?:(?:\\\\)*\\,)|[^,\\]+)+/).map(&:lstrip)
      if label
        label = label.gsub(/\\,/, ',').strip
      end
      label || ''
    end

    def text(str)
      str
    end

    def bibpaper(_lines, id, caption)
      item = ReVIEW::Book::BibpaperIndex::Item.new(id, @bibpaper_index.size + 1, caption)
      @bibpaper_index << item
    end

    def inline_hd(_id)
      ''
    end

    def inline_column(_id)
      ''
    end

    def inline_column_chap(_chapter, _id)
      ''
    end

    def inline_pageref(_id)
      ''
    end

    def inline_tcy(_arg)
      ''
    end

    def inline_balloon(_arg)
      ''
    end

    def inline_w(_s)
      ''
    end

    def inline_wb(_s)
      ''
    end

    def raw(_str)
      ''
    end

    def embed(_lines, _arg = nil)
      ''
    end

    def warn(msg)
      @logger.warn "#{@location}: #{msg}"
    end

    def error(msg = '(no message)')
      if msg =~ /:\d+: error: /
        raise ApplicationError, msg
      else
        raise ApplicationError, "#{@location}: error: #{msg}"
      end
    end

    def texequation(_lines, id = nil, _caption = '')
      item = ReVIEW::Book::EquationIndex::Item.new(id, @equation_index.size + 1)
      @equation_index << item
    end

    def get_chap(_chapter = @chapter)
      ''
    end

    def extract_chapter_id(_chap_ref)
      ''
    end

    def captionblock(_type, _lines, _caption, _specialstyle = nil)
      ''
    end

    CAPTION_TITLES.each do |name|
      class_eval %Q(
        def #{name}(lines, caption = nil)
          captionblock("#{name}", lines, caption)
        end
      )
    end

    # def image_ext
    # end

    def tsize(_str)
      ''
    end

    def inline_raw(_args)
      ''
    end

    def inline_embed(_args)
      ''
    end
  end
end # module ReVIEW
