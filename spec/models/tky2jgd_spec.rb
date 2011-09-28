require 'spec_helper'

describe Tky2jgd do
  #pending "add some examples to (or delete) #{__FILE__}"
	it '緯度経度からメッシュが正しく取得できること' do
		cases = [
						[[35.73104601,139.71227646], '533945']
						]
						
		cases.each do |mycase|
			mesh = Tky2jgd.tkylatlng2mesh(mycase[0])
			mesh.length.should == 6
		end
	end
	it 'iPC形式の緯度経度を世界測地系に変換できること' do
		keta = 3 #小数点以下3位まであってたら、10m以内の誤差
		cases = []
		#東京タワー
		cases << [[32859941, 128792369], [35.658661, 139.745445]]
		#宗谷岬局
		cases << [[41945531, 130819630], [45.51607, 141.94495]]
		#糸満市役所入口
		cases << [[24072068, 117657859],[26.123883, 127.665084]]
		p 'tky2jgd test start'
		cases.each do |mycase|
			latlng = Tky2jgd.ipc2jgd(mycase[0])
			(latlng[0]*1000).to_i.should == (mycase[1][0]*1000).to_i
			(latlng[1]*1000).to_i.should == (mycase[1][1]*1000).to_i
		end

	end
	
end
