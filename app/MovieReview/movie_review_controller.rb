require 'rho/rhocontroller'
require 'helpers/browser_helper'

class MovieReviewController < Rho::RhoController
  include BrowserHelper

  # GET /MovieReview
  def index
    @@moviereviews = [];
          Rho::AsyncHttp.get(
              :url => getZoodyServerURL+"/movie_reviews.xml",
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
            id = ele.elements["id"].text
            @@moviereviews.push MovieReview.new({:id => id, :title => title}) 
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
    @moviereviews = @@moviereviews;
    render :action => :index, :back => "/app"
  end

  # GET /MovieReview/{1}
  def show
    @moviereviews = MovieReview.find(@params['id'])
    if @moviereview
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /MovieReview/new
  def new
    @moviereview = MovieReview.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /MovieReview/{1}/edit
  def edit
    @moviereview = MovieReview.find(@params['id'])
    if @moviereview
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /MovieReview/create
  def create
    @moviereview = MovieReview.create(@params['moviereview'])
    redirect :action => :index
  end

  # POST /MovieReview/{1}/update
  def update
    @moviereview = MovieReview.find(@params['id'])
    @moviereview.update_attributes(@params['moviereview']) if @moviereview
    redirect :action => :index
  end

  # POST /MovieReview/{1}/delete
  def delete
    @moviereview = MovieReview.find(@params['id'])
    @moviereview.destroy if @moviereview
    redirect :action => :index  
  end
end
