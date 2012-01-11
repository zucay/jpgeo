class Tky2jgdController < ApplicationController
  
  def index
    if(params[:latlng].present?)
      ll = params[:latlng]
      
      lat = ll.split(',')[0].to_f
      lng = ll.split(',')[1].to_f
      
      case params[:type]
      when 'ipc2jgd'
        p "HIT"
        oll = Tky2jgd.ipc2jgd([lat,lng])
      when 'jgd2ipc'
        oll = Tky2jgd.jgd2ipc([lat,lng])
      when 'tky2jgd'
        oll = Tky2jgd.tky2ipc([lat,lng])
      else
        oll = Tky2jgd.tky2jgd([lat,lng])
      end
      
      
      @lat = oll[0]
      @lng = oll[1]
    end
    respond_to do |format|
      format.html
      format.json { render :text => [@lat,@lng].to_json }
    end
  end
  
  
  
end
