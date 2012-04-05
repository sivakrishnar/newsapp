require 'rho/rhocontroller'
require 'helpers/browser_helper'

class TrailerController < Rho::RhoController
  include BrowserHelper

  # GET /Trailer
  def index
    @@trailers = [];
          Rho::AsyncHttp.get(
              :url => getZoodyServerURL+"/trailers.xml",
              :callback => url_for(:action => :httpget_callback),
            )
          
    render :action => :wait
  end

 def get_res
      @@get_result
  end
  
  def get_error
      @@error_params
  end
  
  def httpget_callback
     if @params["status"] != "ok"
       @@error_params = @params
       WebView.navigate( url_for(:action => :error) )        
    else
      @@get_result = @params["body"]
  
      begin
        require "rexml/document"
        doc = REXML::Document.new(@@get_result).root
        
        doc.root.elements.each do |ele|
          title = ele.elements["title"].text
          url = ele.elements["url"].text
          id = ele.elements["id"].text
          @@trailers.push Trailer.new({:id => id, :url => url, :title => title}) 
        end
           
      rescue Exception => e
        puts "Error: #{e}"
        @@get_result = "Error: #{e}"
      end
  
      WebView.navigate( url_for(:action => :show_result) )
    end
  end

  def cancel_httpcall
    Rho::AsyncHttp.cancel( url_for( :action => :httpget_callback) )

    @@get_result = 'Request was cancelled.'
    render :action => :index, :back => '/app'
  end

  def show_result
    @trailers = @@trailers;
    render :action => :index, :back => "/app"
  end

  # GET /Trailer/{1}
  def show
     unless @params['id']
          render :action => :index, :back => '/app'
          return;
     end
     puts @params['id'].gsub(/\{/,'').gsub(/\}/,'')
     System.open_url("vnd.youtube:"+@params['id'].gsub(/\{/,'').gsub(/\}/,''))
  end

  # GET /Trailer/new
  def new
    @trailer = Trailer.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Trailer/{1}/edit
  def edit
    @trailer = Trailer.find(@params['id'])
    if @trailer
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Trailer/create
  def create
    @trailer = Trailer.create(@params['trailer'])
    redirect :action => :index
  end

  # POST /Trailer/{1}/update
  def update
    @trailer = Trailer.find(@params['id'])
    @trailer.update_attributes(@params['trailer']) if @trailer
    redirect :action => :index
  end

  # POST /Trailer/{1}/delete
  def delete
    @trailer = Trailer.find(@params['id'])
    @trailer.destroy if @trailer
    redirect :action => :index  
  end
end
