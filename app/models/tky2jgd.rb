require 'mymatrix'
class Tky2jgd < ActiveRecord::Base
	validates_uniqueness_of :meshcode
	#in: latlng[lat, lng](度／float)
	def self.tkylatlng2mesh(latlng)
		#参考：http://www.itt-web.net/modules/xeblog/?action_xeblog_details=1&blog_id=528
		lat = latlng[0]
		lng = latlng[1]
		
		y = lat * 1.5
		x = lng - 100

		a = sprintf("%02d", y.truncate)
		b = sprintf("%02d", x.truncate)
		ydash =(y - y.truncate.to_i)
		
		c = ((y - y.truncate.to_i)*8).truncate
		d = ((x - x.truncate.to_i)*8).truncate
		out = [a,b,c,d].join('')
		#p "mesh:#{out}"
		return out
	end
	def self.tky2jgd(latlng, opts = {:reverse=>false})
		o_latlng = [nil, nil]
		mesh2 = self.tkylatlng2mesh(latlng)
		#tkylatlng2mesh(latlng)で取得されるメッシュは2次メッシュ6桁なので、3次メッシュの中心(55)を追加
		mesh3 = "#{mesh2}55"
		#p mesh3
		ele = self.where("meshcode = '#{mesh3}'")[0]
		if(!ele)
			#p mesh2
			ele = self.where("meshcode like '#{mesh2}%'")[0]
		end
		if(!ele)
			#raise "meshcode not found, latlng=#{latlng[0]}, #{latlng[1]}"
		else
			#dl:経度の秒補正、db:緯度の秒補正
			dl = ele.dL
			db = ele.dB

			if(opts[:reverse] == false)
				o_latlng[0] =latlng[0] + db/3600
				o_latlng[1] =latlng[1] + dl/3600
			else
				o_latlng[0] =latlng[0] - db/3600
				o_latlng[1] =latlng[1] - dl/3600
			end

		end

		return o_latlng		
	end
	
	def self.ipc2jgd(latlng256)
		lat = (latlng256[0].to_f/256)/3600
		lng = (latlng256[1].to_f/256)/3600
		out = self.tky2jgd([lat, lng])
		#p "jgd:#{out}"
		return out
	end
	
	def self.jgd2ipc(latlng)
		jpdegree_ll = self.tky2jgd(latlng, {:reverse => true})
		lat256jp = (jpdegree_ll[0] * 3600 * 256).to_i
		lng256jp = (jpdegree_ll[1] * 3600 * 256).to_i
		out = [lat256jp, lng256jp]

		return out
	end
	
	
	def self.ipc2jgdFile(file)
		mx = MyMatrix.new(file)
		omx = MyMatrix.new
		omx.addHeaders(mx.getHeaders)
		omx.file = mx.file
		siz = mx.size
		mx.each_with_index do |row,	i|
			if(i%100 == 0)
				t = Time.now
				p "#{t} #{i}/#{siz}"
			end
			lat = mx.val(row, 'lat256jp')
			lng = mx.val(row, 'lng256jp')
			if(lat != '')
				out = self.ipc2jgd([lat,lng])
				mx.setValue(row, 'lat', out[0].to_s)
				mx.setValue(row, 'lng', out[1].to_s)
			end
			omx << row.dup
		end
		omx.to_t_with('llconv')
	end
end
