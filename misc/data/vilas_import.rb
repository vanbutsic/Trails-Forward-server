require 'csv'

def handle_row(row, indices, world)
  x = row[ indices[:col] ].to_i
  y = row[ indices[:row] ].to_i
  print "Handling #{x}, #{y}: "
  
  possibly_dirty_water = false #is there a chance we'll need to do a second pass?
  dirty_water = false #second pass needed if true

  resource_tile = world.resource_tile_at x,y
  
  
  resource_tile.skip_version! do #speed things up... since it's Genesis, we should't ever need to rollback
    resource_tile.type = LandTile.to_s
    resource_tile.clear_resources
    
    class_code = row[ indices[:cover_class] ].to_i

    tree_density = row[ indices[:forest_density] ].to_i
    resource_tile.tree_density = case tree_density
      when 255 then nil
      else tree_density.to_f / 100.0
    end  

    devel_density = row[ indices[:devel_density] ].to_i
    resource_tile.housing_density = case devel_density 
      when 0,99,255 then nil
      when 1..6 then (2**(devel_density+1))/128.0
    end

    imperviousness = row[ indices[:imperviousness] ].to_i
    resource_tile.imperviousness = case imperviousness
      when 255 then nil
      else imperviousness.to_f/100.0
    end
    
    print "class_code=#{class_code} tree_density=#{resource_tile.tree_density} housing_density=#{resource_tile.housing_density} imperviousness=#{resource_tile.imperviousness} "
    
      
    case class_code  #most significant digit of class code
    when 11,95  #open water or emergent herbaceous wetlands
      if resource_tile.housing_density and resource_tile.housing_density > 0
        #not really open water, let's treat it as housing
        resource_tile.zoned_use = "Development"
        resource_tile.primary_use = "Housing"
        possibly_dirty_water = true
      else
        resource_tile.type = WaterTile.to_s         
      end
    when 21..24 #developed
      #resource_tile.primary_use = ???
      resource_tile.zoned_use = "Development"
      resource_tile.development_intensity = (class_code - 20)/4.0
      if (resource_tile.development_intensity >= 0.5 or resource_tile.imperviousness >= 0.5) and (resource_tile.housing_density == nil or resource_tile.housing_density <= 0.75)
        resource_tile.primary_use = "Industry"
      else
        resource_tile.primary_use = "Housing"          
      end
      
      possibly_dirty_water = true 
    when 41..71,90 #forest, scrub, herbaceous
      resource_tile.primary_use = "Forest"
      resource_tile.tree_species = case class_code
        when 41 then ResourceTile::Verbiage[:tree_species][:deciduous]
        when 42 then ResourceTile::Verbiage[:tree_species][:coniferous]
        when 43 then ResourceTile::Verbiage[:tree_species][:mixed]
      end
      possibly_dirty_water = true     
    when 81..82 #pasture or crops
      resource_tile.primary_use = case class_code
        when 81 then "Agriculture/Pasture"
        when 82 then "Agriculture/Cultivated Crops"
      end
      resource_tile.zoned_use = "Agriculture"
      possibly_dirty_water = true
    when 255 #no data, lots of this at the edges, so let's just call it water... island county :-)
      resource_tile.type = WaterTile.to_s
    end #case
    puts "#{resource_tile.type}"
    
    if possibly_dirty_water and resource_tile.class == WaterTile
      resource_tile.clear_resources
      resource_tile.type = LandTile.to_s
      dirty_water = true
    end
    
  end #skip_version
  
  if dirty_water #do a second pass
    handle_row(row, indices, world)
  end
  
end

world = World.find ARGV[0]
reader = CSV.open("misc/data/vilas_conserv_game_spatial_1_acre_inputs.csv", "r")
header = reader.shift
indices = {:row => header.index("ROW"), :col => header.index("COL"), :cover_class => header.index("LANDCOV2001"), :imperviousness => header.index("IMPERV%2001") , :devel_density => header.index("HDEN00"), :forest_density => header.index("CANOPY%2001")}
reader.each{|row| handle_row(row, indices, world)}
