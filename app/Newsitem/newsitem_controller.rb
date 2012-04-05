require 'rho/rhocontroller'
require 'helpers/browser_helper'

class NewsitemController < Rho::RhoController
  include BrowserHelper

  # GET /Newsitem
  def index
    @@newsitems = [];
            Rho::AsyncHttp.get(
                :url => getZoodyServerURL+"/newsitems.xml",  
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

            @@newsitems.push Newsitem.new({:id => id, :title => title}) 
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
    @newsitems = @@newsitems;
    render :action => :index, :back => "/app"
  end

  # GET /Newsitem/{1}
  def show
    @newsitem = Newsitem.find(@params['id'])
    if @newsitem
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Newsitem/new
  def new
    @newsitem = Newsitem.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Newsitem/{1}/edit
  def edit
    @newsitem = Newsitem.find(@params['id'])
    if @newsitem
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Newsitem/create
  def create
    @newsitem = Newsitem.create(@params['newsitem'])
    redirect :action => :index
  end

  # POST /Newsitem/{1}/update
  def update
    @newsitem = Newsitem.find(@params['id'])
    @newsitem.update_attributes(@params['newsitem']) if @newsitem
    redirect :action => :index
  end

  # POST /Newsitem/{1}/delete
  def delete
    @newsitem = Newsitem.find(@params['id'])
    @newsitem.destroy if @newsitem
    redirect :action => :index  
  end
end
