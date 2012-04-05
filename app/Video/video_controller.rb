require 'rho/rhocontroller'
require 'helpers/browser_helper'

class VideoController < Rho::RhoController
  include BrowserHelper

  # GET /Video
  def index
   @@videos = [];
        Rho::AsyncHttp.get(
            :url => getZoodyServerURL+"/videos.xml",
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
          @@videos.push Video.new({:id => id, :url => url, :title => title}) 
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
  @videos = @@videos;
  render :action => :index, :back => "/app"
end

  # GET /Video/{1}
  def show
      unless @params['id']
          render :action => :index, :back => '/app'
          return;
      end 
      id = @params['id'].gsub(/\{/,'').gsub(/\}/,'')
      System.open_url("vnd.youtube:#{id}?fs=1")
  end

  # GET /Video/new
  def new
    @video = Video.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Video/{1}/edit
  def edit
    @video = Video.find(@params['id'])
    if @video
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Video/create
  def create
    @video = Video.create(@params['video'])
    redirect :action => :index
  end

  # POST /Video/{1}/update
  def update
    @video = Video.find(@params['id'])
    @video.update_attributes(@params['video']) if @video
    redirect :action => :index
  end

  # POST /Video/{1}/delete
  def delete
    @video = Video.find(@params['id'])
    @video.destroy if @video
    redirect :action => :index  
  end
end
