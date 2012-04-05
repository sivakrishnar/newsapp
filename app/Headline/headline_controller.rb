require 'rho/rhocontroller'
require 'helpers/browser_helper'
require "rexml/document"

class HeadlineController < Rho::RhoController
  include BrowserHelper

  # GET /Headline
  def index
    @@headlines = [];
          Rho::AsyncHttp.get(
              :url => getZoodyServerURL+"/headlines.xml",
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
          doc = REXML::Document.new(@@get_result).root
          
          doc.root.elements.each do |ele|
            title = ele.elements["title"].text
            id = ele.elements["id"].text
            @@headlines.push Headline.new({:id => id, :title => title}) 
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
    @headlines = @@headlines;
    render :action => :index, :back => "/app"
  end

  # GET /Headline/{1}
  def show
    @headline = Headline.find(@params['id'])
    if @headline
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Headline/new
  def new
    @headline = Headline.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Headline/{1}/edit
  def edit
    @headline = Headline.find(@params['id'])
    if @headline
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Headline/create
  def create
    @headline = Headline.create(@params['headline'])
    redirect :action => :index
  end

  # POST /Headline/{1}/update
  def update
    @headline = Headline.find(@params['id'])
    @headline.update_attributes(@params['headline']) if @headline
    redirect :action => :index
  end

  # POST /Headline/{1}/delete
  def delete
    @headline = Headline.find(@params['id'])
    @headline.destroy if @headline
    redirect :action => :index  
  end
end
