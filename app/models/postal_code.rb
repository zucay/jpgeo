# -*- coding: utf-8 -*-
class PostalCode < ActiveRecord::Base
  def self.load(file)
    if(!file)
      p 'you can download postal codes csv at http://www.post.japanpost.jp/zipcode/download.html'
      raise 'file not found'
    end
    colnames = self.column_names.join(',')
    sql = "INSERT INTO postal_codes(#{colnames}) VALUES "
    recs = []
    at = Time.now.to_s(:db)
    open(file,'r:Shift_JIS') do |fi|
      fi.each_with_index do |line, i|
        str = "(#{i+1},#{line.chomp},'#{at}','#{at}')".gsub(/"/, '\'')
        recs << str
      end
    end
    sql = sql + recs.join(',') + ';'
    p 'sql execute'
    self.connection.execute(sql)
  end
  

  #utility methods
  def self.cities(pref)
    cities = []
    if(!pref)
      recs = []
    else
      recs = PostalCode.where('pref = ?', pref)
    end

    recs.each do |rec|
      cities << rec.city
    end
    cities = cities.uniq
    return cities
  end
end
