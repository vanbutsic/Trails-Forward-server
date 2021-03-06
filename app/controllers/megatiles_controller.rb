class MegatilesController < ApplicationController
  before_filter :authenticate_user!
    
  # GET /megatiles
  # GET /megatiles.xml
  def index
    @world = World.find(params[:world_id])
    
    authorize! :do_things, @world
    
    if params.has_key? :x_min
      #if @megatiles.count * @world.megatile_width > 1000
      x_min = params[:x_min].to_i
      x_max = params[:x_max].to_i
      y_min = params[:y_min].to_i
      y_max = params[:y_max].to_i
      
      if (x_max - x_min)*(y_max - y_min) > 2000
        render :status => :forbidden, :text => "Request too large"
        return
      end
    
      @megatiles = Megatile.where(:world_id => @world.id).where("x >= :x_min AND x<= :x_max AND y>=:y_min AND y<=:y_max", 
       {:x_min => x_min, :x_max => x_max, :y_min => y_min, :y_max => y_max})
    else
      if @world.width * @world.height > 2000
        render :status => :request_entity_too_large, :text => "Request too large"
        return
      end
      @megatiles = @world.megatiles
    end
    respond_to do |format|
      format.xml  { render_for_api :megatile_with_resources, :xml  => @megatiles, :root => :megatiles  }
      format.json { render_for_api :megatile_with_resources, :json => @megatiles, :root => :megatiles  }
    end
  end

  # GET /megatiles/1
  # GET /megatiles/1.xml
  def show
    @megatile = Megatile.find(params[:id])
    authorize! :do_things, @megatile.world


    respond_to do |format|
      format.xml  { render_for_api :megatile_with_resources, :xml  => @megatile, :root => :megatile  }
      format.json { render_for_api :megatile_with_resources, :json => @megatile, :root => :megatile  }
    end
  end

end
