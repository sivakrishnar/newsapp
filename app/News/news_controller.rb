require 'rho/rhocontroller'
require 'helpers/browser_helper'

class NewsController < Rho::RhoController
  include BrowserHelper

  # GET /News
  def index
    ##  @news = News.find(:all)
    ##  render :back => '/app'
    
    @@allnews = [];
            Rho::AsyncHttp.get(
                :url => getZoodyServerURL+"/news_items.xml",
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
        puts @@get_result
        doc = REXML::Document.new(@@get_result).root
        
        doc.root.elements.each do |ele|
          title = ele.elements["title"].text
          content = ele.elements["content"].text
          id = ele.elements["id"].text
          @@allnews.push News.new({:id => id.to_i, :link => content, :title => title}) 
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
    @news = @@allnews;
    render :action => :index, :back => "/app"
  end


  # GET /News/{1}
  def show
    p @params
    unless @params['id']
        render :action => :index, :back => '/app'
        return;
    end
    @news = @@allnews[@params['id']]
    p @news
    render :action => :show, :back => url_for(:action => :index)
  end

  # GET /News/new
  def new
    @news = News.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /News/{1}/edit
  def edit
    @news = News.find(@params['id'])
    if @news
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /News/create
  def create
    @news = News.create(@params['news'])
    redirect :action => :index
  end

  # POST /News/{1}/update
  def update
    @news = News.find(@params['id'])
    @news.update_attributes(@params['news']) if @news
    redirect :action => :index
  end

  # POST /News/{1}/delete
  def delete
    @news = News.find(@params['id'])
    @news.destroy if @news
    redirect :action => :index  
  end
end
