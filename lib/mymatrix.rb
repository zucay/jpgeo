#!/usr/bin/ruby -Ku
# -*- encoding: UTF-8 -*-

require 'rubygems'
require 'spreadsheet'
require 'nkf'
#require 'kconv'
$KCODE='UTF8'
require 'logger'


class MyMatrix
	attr_accessor :file, :internal_lf, :mx
	include Enumerable
	#to_t()の際のセパレータ。
	SEPARATOR = "\t"

	def initialize(file=nil)
		
		#platform check
		if(RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|cygwin|bccwin/)
			$mymatrix_filesystem = 's'
		elsif(RUBY_PLATFORM.downcase =~ /darwin/)
			$mymatrix_filesystem = 'm'
		elsif(RUBY_PLATFORM.downcase =~ /linux/)
			$mymatrix_filesystem = 'u'
		else
			$mymatrix_filesystem = 'u'
		end
	
	
		
		#内部改行コード。
		@internal_lf = '<br>'
		
		@log = Logger.new('MyMatrix_ERR.log')
		@log.level = Logger::DEBUG
		@file  = file
		
		@mx = []
		if(@file =~ /\.xls$/)
			@mx = makeMatrixFromXLS(@file)
		elsif(@file =~ /(\.tsv|\.txt|\.TSV|\.TXT)/)
			@mx = makeMatrixFromTSV(@file)
		elsif(@file =~ /(\.csv|\.CSV)/)
			require 'CSV'
			@mx = makeMatrixFromTSV(@file, ', ')
		elsif(@file == nil)
	
		else
			#デフォルトはTSVで読み込むようにする。
			@mx = makeMatrixFromTSV(@file)
		end

		#@mxの末尾に空レコードが入っていたら、その空白を削除
		while(@mx[@mx.size-1] && @mx[@mx.size-1].join == '')
			@mx.pop
		end
		if(@mx.size == 0)
			@mx = []
		end
		@headers = @mx.shift
		registerMatrix
		return self
	end
	
	#CP932を正しく扱うため、変換関数を実装する。
	def self.tosjis(str)
		#-xは半角カナを全角にするのを抑止するオプション。
		out = NKF.nkf('-W -x -s --cp932', str)
		return out
	end
	def self.toutf8(str)
		#out = NKF.nkf('-x -w --cp932', str)
		#入力がShift-jisであるとする。
		out = NKF.nkf('-S -x -w --cp932', str)
		return out		
	end
	def self.toUtf8Mac(str)
		#現状、UTF8-MACに対応した変換方法がない
		#out = NKF.nkf('', str)
		out = str
	end
	def registerMatrix
		@headerH = Hash.new
		if(!@headers)
			@headers = []
		end
		@headers.each_with_index do |colName, i|
			@headerH[colName] = i
		end
		fillEmptyCell
	end

	def fillEmptyCell
		headerSize = getHeaders.size
		@mx.each_with_index do |row, i|
			if(row.size < headerSize)
				(headerSize - row.size).times do |i|
					row << ''
				end
			elsif(row.size > headerSize)
				warn("row is large:#{@file} line #{i} / rowSize #{row.size} / headersize #{headerSize}")
				#raise "rowsize error"
			end
		end
	end

	def encodePath(path)
		case $mymatrix_filesystem
		when 'u'
			#utf8=>utf8なので何もしない
			#path = MyMatrix.toutf8(path)
			#path.encode('UTF-8')
			path
		when 's'
			path = MyMatrix.tosjis(path)
			#path.encode('Windows-31J')
		when 'w'
			path = MyMatrix.tosjis(path)
			#path.encode('Windows-31J')
		when 'm'
			path = MyMatrix.toUtf8Mac(path)
		end
	end
	def makeMatrixFromXLS(xlsFile)
		out = []
		#todo xlsFileがなかったら作成
		p encodePath(xlsFile)
		xl = Spreadsheet.open(encodePath(xlsFile), 'rb')

		sheet = xl.worksheet(0)
		rowsize = sheet.last_row_index
		(rowsize+1).times do |i|
			row = sheet.row(i)
			orow = []
			row.each do |ele|
				#様々な型で値が入っている。改行も入っている
				if(ele.class == Float)&&(ele.to_s =~ /(\d+)\.0/)
					ele = $1
				end
				if(ele.class == Spreadsheet::Formula)
					ele = ele.value
				end
				if(ele == nil)
					ele = ''
				end
				ele = ele.to_s.gsub(/\n/, '<br>')
				orow << ele
			end
			out << orow
		end
		
		return out
	end

	def makeMatrixFromTSV(file, sep="\t")
		out = []
		if(!File.exist?(encodePath(file)))
			open(encodePath(file), 'w') do |fo|
				fo.print("\n\n")
			end
		end
		#fi = open(file.encode('Windows-31J'), "r:Windows-31J")
		fi = open(encodePath(file), "r:Windows-31J")
		fi.each do |line|
			#row = line.encode('UTF-8').chomp.split(/#{sep}/)
			row = MyMatrix.toutf8(line).chomp.split(/#{sep}/)
			#「1,300台」などカンマが使われている場合、「"1,300台"」となってしまうので、カンマを無視する
			newRow = []
			row.each do |cell|
				stri = cell.dup
				stri.gsub!(/^\"(.*)\"$/, '\1')
				#"
				stri.gsub!(/""/, '"')
				newRow << stri
			end
			out << newRow
		end
		fi.close
		return out
	end
	
	def makeMatrixFromCSV(file)
		require 'csv'
		out = []
		
		if(!File.exist?(encodePath(file)))
			open(encodePath(file), 'w') do |fo|
				fo.print("\n\n")
			end
		end
		#CSV.open(file.encode('Windows-31J'), 'r') do |row|
		CSV.open(encodePath(file), 'r') do |row|
			#「1,300台」などカンマが使われている場合、「"1,300台"」となってしまうので、カンマを無視する
			newRow = []
			row.each do |cell|
				#cell = cell.encode('UTF-8')
				cell = MyMatrix.toutf8(cell)
				cell = cell.gsub(/^\"/, "")
				cell = cell.gsub(/\"$/, "")
				#"
				newRow << cell
			end
			out << newRow
		end
		return out
	end

	def isEnd(row)
		out = true
		row.each do |cell|
			if(cell != "")
				out = nil
				break
			end
		end
		return out
	end
	
	def getColumn(colName)
		out = []
		@mx.each do |row|
			begin
				out << getValue(row, colName)
			rescue
				raise "#{colName} notfound: #{row}"
			end
		end
		return out
	end
	
	def getValues(colName)
		return getColumn(colName)
	end
	
	def getColumns(colNames)
		out = []
		colNames.each do |colName|
			out << getColumn(colName)
		end
		return out
	end
	def getColumnsByMatrix(colNames)
		out = MyMatrix.new
		colNames.each do |colName|
			col = getColumn(colName)
			out.addColumn(colName, col)
		end
		return out
	end
	
	def getValue(row, str)
		out = nil
		index = @headerH[str]
		if(index)
			out = row[index]
			#お尻のセルでNULLの場合などは、nilが返却されてしまう。なので、''となるようにする。
			if(!out)
				out = ''
			end
			#参照を渡さないためdupする
			out = out.dup
		else
			raise "header not found:#{str} file:#{@file}"
		end
		return out
	end
	alias val getValue
=begin
	def getValues(row, arr)
		out = []
		arr.each do |ele|
			out << getValue(row, ele)
		end
		if(out.size == 0)
			out = nil
		end
		return out
	end
=end
	def setValue(row, str, value)
		index = @headerH[str]
		if(!index)
			addHeaders([str])
		end
		#参照先の値も変更できるように、破壊メソッドを使う。row[@headerH[str]] = valueでは、参照先が切り替わってしまうので、値の置き換えにならない。
		#findなどで取得したrowに対して処理を行う際に必要な変更。
		if(row[@headerH[str]].class == String)
			row[@headerH[str]].sub!(/^.*$/, value)
		else
			#raise('not string error.')
			#todo 強烈なバグな気もするが、例外を回避し値を代入2010年12月15日
			begin
				row[@headerH[str]] = value.to_s
			rescue
				row[@headerH[str]] = ''
			end
		end
	end
	def each
		@mx.each do |row|
			yield(row)
		end
	end
	def reverse
		out = empty
		
		@mx.reverse.each do |row|
			out << row
		end
		return out
	end


	def size
		return @mx.size
	end
	def [](i,j)
		return @mx[i][j]
	end
	
	def [](i)
		return @mx[i]
	end
	
	def +(other)
		out = MyipcMatrix.new
		
		othHeaders = other.getHeaders
		selHeaders = getHeaders
		
		selHeaders.each do |header|
			out.addColumn(header, getColumn(header))
		end
		
		othHeaders.each do |header|
			out.addColumn(header, other.getColumn(header))
		end
		
		return out
	end
	
	def addColumn(header, column)
		pushColumn(header, column)
	end
	def <<(row)
		addRow(row)
	end
	def addRow(row)
		if(row.class != Array)
			row = [row]
		end
		row.size.times do |i|
			if(row[i] == nil)
				row[i] = ''
			end
		end
		
		headerSize = getHeaders.size
		rowSize = row.size
		if(headerSize > rowSize)
			(headerSize - rowSize).times do |i|
				row << ''
			end
		elsif(rowSize > headerSize)
			raise("row size error. headerSize:#{headerSize} rowSize:#{rowSize}")
		end
		@mx << row.dup
	end
	def [](i)
		return @mx[i]
	end
	def []=(key, value)
		@mx[key] = value
	end
	def pushColumn(header, column)
		colPos = @headers.length
		@headers << header
		registerMatrix
		column.each_with_index do |cell, i|
			if(@mx[i] == nil)
				@mx[i] = []
			end
			@mx[i][colPos] = cell
		end
	end
	def unShiftColumn(header, column)
		@headers.unshift(header)
		registerMatrix
		column.each_with_index do |cell, i|
			if(@mx[i] == nil)
				@mx[i] = []
			end
			#todo:ヘッダよりでかいrowがある場合バグる。期待していない一番右の値が取れてしまう。
			@mx[i].unshift(cell)
		end
	end
	
	def shiftColumn()
		header = @headers.shift
		column = []
		registerMatrix
		@mx.each do |row|
			column << row.shift
		end
		return header, column
	end
	def divide(lineNum, outFile)
		mymxs = []
		tmp = MyMatrix.new
		tmp.addHeaders(getHeaders)
		@mx.each_with_index do |row, i|
			tmp << row.dup
			if((i+1) % lineNum == 0)
				mymxs << tmp
				tmp = MyMatrix.new
				tmp.addHeaders(getHeaders)
			end
		end
		mymxs << tmp
		
		mymxs.each_with_index do |mymx, i|
			name = "#{outFile}_#{i}.txt"
			mymx.to_t(name)
		end
	end
		
	def localEncode(v, enc = 's')
		case enc
		when 'u'
			str = MyMatrix.toutf8(v)
		when 's'
			str = MyMatrix.tosjis(v)
		else
			str = MyMatrix.tosjis(v)
		end
	end
	#使い方はto_t()を参照。yield。
	def to_text(outFile)
		outFile = encodePath(outFile)
		out = []
		out << @headers
		@mx.each do |row|
			out << row
		end
		begin
			fo = open(outFile, 'w')
		rescue
			p "file is opened...#{outFile}"
			sleep(5)
			retry
		end
		out.each_with_index do |row, i|
			if(row == nil)
				warn("line #{i} is nil")
				fo.print("")
			else 
				str = yield(row)
				fo.print(str)
			end
			fo.print("\n")
		end
		fo.close
	end
	def to_t(outFile=nil, enc='s')
		if(!outFile)
			outFile = @file
		end
		to_text(outFile) do |row|
			begin
				str = localEncode(row.join(SEPARATOR), enc)
			rescue Encoding::UndefinedConversionError
				raise "windows-31J encode error."
				@log.debug(row.join(SEPARATOR))
			end
			str
		end
	end
	def to_t_with(postfix="out", enc='s')
		dir = File.dirname(@file)
		#ext = File.extname(@file)
		ext = '.txt'
		basename = File.basename(@file, ".*")
		opath = (encodePath("#{dir}/#{basename}_#{postfix}#{ext}"))
		to_t(opath, enc)
		return opath
	end
	def to_csv(outFile)
		#"E"nglish"を吐き出すと""E""nglish""となることを期待しているが、
		#"E""nglish"となってしまう。→読み込み時セル頭・末尾の"を削除しているため
		to_text(outFile) do |row|
			orow = []
			row.each do |cell|
				str = cell.dup
				str = str.gsub(/\"/, '""')
				str = "\"#{str}\""
				orow << str
			end
			ostr = orow.join(',')
			ostr = ostr.encode('Windows-31J')
			ostr
		end
	end
	def getHeaders
		out = @headers.dup
		return out
	end
	def replaceHeader(before, after)
		@headers[@headerH[before]] = after
		registerMatrix
	end
	def index(colName, value)
		out = nil
		col = getColumn(colName)
		col.each_with_index do |cell, i|
			if(value == cell)
				out = i
				break
			end
		end
		return out
	end
		
	def searchIndexes(colName, value)
		out = []
		col = getColumn(colName)
		col.each_with_index do |cell, i|
			if(value == cell)
				out << i
			end
		end
		return out
	end
	def search(colName, value)
		indexes = []
		col = getColumn(colName)
		col.each_with_index do |cell, i|
			if(value == cell)
				indexes << i
			end
		end
		out = self.empty
		indexes.each do |index|
			out << @mx[index]
		end
		return out
	end
	def addHeaders(aheaders)
		@headers.concat(aheaders).uniq!
		
		registerMatrix
	end
	def addHeader(key)
		addHeaders([key])
	end
	def size
		return @mx.size
	end
	
	def uniq!
		@mx.uniq!
	end
	
	def shift
		return @mx.shift
	end
	def unshift(var)
		return @mx.unshift(var)
	end
	def pop
		return @mx.pop
	end
	def push(var)
		return @mx.push(var)
	end
	def delete_at(pos)
		@mx.delete_at(pos)
	end
	def delete_if
		out = @mx.delete_if do |row|
			yield(row)
		end
		@mx = out
	end
	def delete(v)
		@mx.delete(v)
	end
	#ブロックがTrueになる、配列（参照）を返却するメソッド
	def find
		#todo rowsを返却するのと、Mymatrxixを返却するのとどっちがイイのか。。
		rows = []
		@mx.each do |row|
			if(yield(row))
				rows << row.dup
			end
		end
		return rows
	end
	
	def select(headers)
		out = MyMatrix.new
		headers.each do |header|
			out.addColumn(header, getColumn(header))
		end
		out.file = @file
		return out
	end
	
	def makeHash(fromColName, toColName)
		out = Hash.new
		@mx.each do |row|
			from = getValue(row, fromColName)
			to = getValue(row, toColName)
			out[from] = to
		end
		return out
	end
	
	#MyipcMatrixとの互換性のため
	def getCrrValue(row, str)
		getValue(row, str)
	end
	
	def concatCells(headers, colname)
		addHeaders([colname])
		@mx.each do |row|
			val = []
			headers.each do |header|
				val << getValue(row, header)
			end
			setValue(row, colname, val.join('_').gsub(/_+/, '_'))
		end
	end
	def getPath
		return @file
	end
	def setPath(path)
		@file = path
	end
	def searchHeader(str)
		out = []
		getHeaders.each do |header|
			if(header =~ /#{str}/)
				out << header
			end
		end
	end
	
	#n分割した配列を返却する
	def devide(n)
		out = []
		mx = @mx.dup
		eleSize = mx.size/n
		n.times do |i|
			o = self.empty
			eleSize.times do |j|
				o << mx.shift
			end
			out << o
		end
		#@mx.size%n分余ってるので、追加
		mx.each do |ele|
			out[n-1] << ele
		end
		return out
	end
	#compareHeaderの値の中に、valuesに書かれた値があったら、targetHeaderにフラグを立てる
	def addFlg(targetHeader, compareHeader, values, flgValue='1')
		compares = getColumn(compareHeader)
		values.each do|value|
			i = compares.index(value)
			if(i)
				setValue(@mx[i], targetHeader, flgValue)
			else
				#raise "VALUE NOT FOUND:#{value}"
			end
		end
	end

	def without(str)
		newHeaders = []
		@headers.each do |header|
			if(header =~ /#{str}/)
			else
				newHeaders << header
			end
		end
		out = select(newHeaders)
		return out
	end
	
	def empty
		out = self.dup
		out.empty!
		return out
	end
	def empty!
		@mx = []
	end
	def fill(rows)
		rows.each do |row|
			self << row
		end
		return self
	end
		
	
	def with_serial(headerName = 'No.')
		out = self.empty
		out.addHeaders([headerName], 1)
		self.each_with_index do |row, i|
			no = i + 1
			newRow = [no].concat(row)
			out << newRow
		end
		return out
	end
	
	def count(header, value)
		out = 0
		arr = getColumn(header)
		arr.each do |ele|
			if(ele =~ /#{value}/)
				out += 1
			end
		end
		return out
	end
	#全件カウントして、[value, count] という配列に格納する
	def countup(header)
		out = []
		values = getColumn(header).uniq
		values.each do |value|
			out << [value, self.count(header, value)]
		end
		return out
	end
	def getDoubles(arr)
		doubles = arr.select do |e|
		 arr.index(e) != arr.rindex(e)
		end
		doubles.uniq!
		return doubles
	end
	
	def filter(header, value)
		out = empty
		@mx.each do|row|
			v = getValue(row, header)
			if(v == value)
				out << row
			end
		end
		return out
	end
	#配列と引き算とかする際に使われる。
	def to_ary
		arr = []
		@mx.each do |row|
			#arr << row.dup
			arr << row
		end
		return arr
	end
	def to_s
		out = ''
		@mx.each do |row|
			out = out + row.to_s + "\n"
		end
		return out
	end
	def to_s_with_header
		out = self.getHeaders.to_s + "\n"
		out = out + self.to_s
	end
	def concat(mx)
		if(self.getHeaders.size == 0)	
			self.addHeaders(mx.getHeaders)
		end
		if(mx.getHeaders == self.getHeaders)
			mx.each do |row|
				o = []
				mx.getHeaders.each do |head|
					self.setValue(o, head, mx.getValue(row, head))
				end
				self << o
			end
		else
			a = mx.getHeaders
			b = self.getHeaders
			
			diff = ((a|b) - (a&b)).join(',')
			raise "format error.#{diff}if you want to concat file, use concatFile()"
		end
		return self
	end
	def concatFile(file)
		mx = MyMatrix.new(file)
		self.concat(mx)
		return self
	end
	#フォルダ内ファイルの結合。絶対パスを指定する
	def concatDir(dir)
		dir = File.expand_path(dir)
		Dir.entries(dir).each do |ent|
			if(ent =~ /^\./)
			else
				#p ent

				file = dir + '/' + ent
				#p "concat:#{file}"
				nmx = MyMatrix.new(file)
				self.concat(nmx)
			end
		end

	end
=begin
  def concat!(mx)
		o = self.concat(mx)
		self = o
		return self
	end
	def concatFile!(file)
		o = self.concatFile(file)
		self = o
		return self
	end
=end
	def flushCol(colname)
		@mx.each do |row|
			self.setValue(row, colname, '')
		end
		return self
	end
	def sortBy(colname, reverse=false)
		sortmx = []
		self.each do |row|
			key = self.getValue(row, colname)
			sortmx << [key, row]
		end
		sortmx.sort!
		self.empty!
		sortmx.each do |keyrow|
			self << keyrow[1]
		end
		return self
	end
	def dupRow(row, destmx, destrow, headers)
		headers.each do |head|
			val = self.getValue(row, head)
			destmx.setValue(destrow, head, val)
		end
		return destrow
	end
=begin	
	def to_xls(opts)
		if(opts[:out] =~ /.xls$/)
		else
			raise "not outfile"
		end
		opts[:template] ||= opts[:out]
		
		opts[:offset_r] ||= 0
		opts[:offset_c] ||= 0

		xl = Spreadsheet.open(encodePath(opts[:template]), 'r')
		sheet = xl.worksheet(0)
		@headers.each_with_index do |head, i|
			ab_row = opts[:offset_r]
			ab_col = opts[:offset_c] + i
			sheet[ab_row, ab_col] = head			
		end
		self.each_with_index do |row, i|
			row.each_with_index do |cell, j|
				ab_row = opts[:offset_r] + i + 1
				#↑ヘッダ分1オフセット 
				ab_col = opts[:offset_c] + j				
				sheet[ab_row, ab_col] = cell
			end
		end
		
		xl.write(opts[:out])
		
	end
=end
end

#ruby -Ks で利用する場合。obsolate
class SjisMyMatrix < MyMatrix
	def getValue(row, col)
		col = MyMatrix.toutf8(col)
	 MyMatrix.tosjis(super(row, col))
	end
	def setValue(row, col, value)
		col = MyMatrix.toutf8(col)
		value = MyMatrix.toutf8(value)
		super(row, col, value)
	end
	def addHeaders(hs)
		arr =[]
		hs.each do |ele|
			arr << MyMatrix.toutf8(ele)
		end
		super(arr)
	end
	def getHeaders
		out = []
		arr = super()
		arr.each do |ele|
			out << MyMatrix.tosjis(ele)
		end
		return out
	end
end



class MyRailsMatrix < MyMatrix
	def headers2db(t)
		getHeaders.each do |header|
			t.column header, :string
		end
	end
end

