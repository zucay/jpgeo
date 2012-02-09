# -*- coding: utf-8 -*-
class AddrController < InheritedResources::Base
  def cities
    @cities = PostalCode.cities(params[:pref])
    p @cities.join('/')
    respond_to do |format|
      format.html { render :json => @cities }
      format.json { render :json => @cities }
    end
  end
end
