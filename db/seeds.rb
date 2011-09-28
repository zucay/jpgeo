# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)


#TKY2JGD
open('doc/TKY2JGD.par') do |fi|
	fi.gets
	fi.gets
	fi.each_with_index do |line, i|
		if(i%1000 == 0)
			p "tky2jgd #{i}"
		end
		row = line.chomp.split
		Tky2jgd.create({:meshcode => row[0], :dB => row[1], :dL => row[2]})
	end
end

=begin
#高速化コード（http://d.hatena.ne.jp/takihiro/20091002/1254546608を参考に書いたが、うまく動いていない）
records = []
open('doc/TKY2JGD.par') do |fi|
	fi.gets
	fi.gets
	fi.each_with_index do |line, i|
		if(i%10000 == 0)
			p "tky2jgd #{i}"
		end
		row = line.chomp.split
		#Tky2jgd.create({:meshcode => row[0], :dB => row[1], :dL => row[2]})
		#time = Time.now.to_s(:db)
		time = ActiveRecord::Base.connection.quote(Time.now.utc)
		records << "(#{row.join(',')}, #{time}, #{time})"
	end
end
p 'sql exec'
p Tky2jgd.connection.execute(<<-SQL)
		INSERT INTO tky2jgds
		(meshcode, dB, dL, created_at, updated_at)
		VALUES #{records.join(',')}
SQL
=end
