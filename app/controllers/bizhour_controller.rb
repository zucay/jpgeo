class BizhourController < ApplicationController
  def index
    @hours = []
    if(params[:h])
      @hours = BizHour.new.parse(params[:h])
    end
  end
end

class BizHour
  DH = %w[SUN MON TUE WED THU FRI SAT]
  def parse(str)
    if(str =~ /(\d{1,2}):(\d{1,2}).*?(\d{1,2}):(\d{1,2})/)
      setRange($1, $2, $3, $4)
    else
      defaultSet
    end
  end
  def setRange(sh, sm, eh, em)
    out = []
    5.times do |w|
      7.times do |d|
        out << "week #{w}, #{DH[d]} : #{sh}:#{sm}-#{eh}:#{em}"
      end
    end
    return out
  end
  def defaultSet
    out = []
    5.times do |w|
      7.times do |d|
        out << "week #{w}, #{DH[d]} : 0:00-23:59"
      end
    end
    return out
  end
end
