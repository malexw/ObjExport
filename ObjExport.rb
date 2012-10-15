#
# OBJ Export
#
# Exports a Google SketchUp drawing to an OBJ format file. Includes support for materials.
# Output file is optimized for file size.
#
# Copyright Alex Williams 2009
# http://blinkenlights.ca

class Array
    # Appends the passed object to the array if it isn't in the array already, then returns the index to the object
    def add_unique( val )
        location = self.index( val )

        if( location == nil )
            self << val
            return (self.length - 1)
        end

        return location
    end
end

def build_geometry( vertices, normals, uvs, indices, materials )

    print "Generating geometry... "

    Sketchup.active_model.entities.each { | entity |
        if( entity.typename == "Face" ) then
            face_mesh = entity.mesh 5
            uv_getter = entity.get_UVHelper( true, false, Sketchup.create_texture_writer )
            point_count = face_mesh.count_points
            temp_indices = Array.new

            for i in 1..point_count
                temp_indices << ( vertices.add_unique( face_mesh.point_at( i ) ) + 1 )
                temp_indices << ( uvs.add_unique( uv_getter.get_front_UVQ( face_mesh.point_at( i ) ) ) + 1 )
                temp_indices << ( normals.add_unique( face_mesh.normal_at( i ) ) + 1 )
            end

            face_mesh.polygons.each { | poly |
                indices << materials.add_unique( entity.material )

                poly.each { | poly_index |
                    offset = ( (poly_index.abs - 1) * 3 )
                    indices << temp_indices[ offset ] << temp_indices[ offset+1 ] << temp_indices[ offset+2 ]
                }
            }
        end
    }

    print "done.\n"
end

def write_geometry( file_path, vertices, normals, uvs, indices, materials )

    triangle_count = indices.length / 10

    print "Writing #{triangle_count.to_s} triangles to .obj file... "
    obj_output = open( "#{file_path}.obj", "w" )
    obj_output.print "# Exported from Google SketchUp by ObjExport\n"
    obj_output.print "mtllib #{file_path.split('\\').at(-1)}.mtl\n\n"
    mtl_output = open( "#{file_path}.mtl", "w" )
    mtl_output.print "# Exported from Google SketchUp by ObjExport\n"

    vertices.each { | vertex | obj_output.print "v #{vertex.to_a.join( " " )}\n" }
    uvs.each { | uv | obj_output.print "vt #{uv.to_a.join( " " )}\n" }
    normals.each { | normal | obj_output.print "vn #{normal.to_a.join( " " )}\n" }

    materials.each { | material |
        obj_output.print "usemtl #{material.name}\n"

        mtl_output.print "\nnewmtl #{material.name}\n"
        mtl_output.print "Kd #{material.color.red/255.0} #{material.color.green/255.0} #{material.color.blue/255.0}\n"
        if(material.texture) then
            mtl_output.print "map_Kd #{File.basename(material.texture.filename)}\n"
        end
        mtl_output.print "illum 1\n"

        for i in 1..triangle_count
            if( material == materials[ indices[ (i-1) * 10 ] ] )
                obj_output.print "f"
                for j in 0..2
                    offset = ( (i-1) * 10 ) + ( j * 3 ) + 1
                    obj_output.print " #{indices[ offset ].to_s}/#{indices[ offset+1 ].to_s}/#{indices[ offset+2 ].to_s}"
                end
                obj_output.print "\n"
            end
        end
    }

    mtl_output.close
    obj_output.close
    print "done.\n"
end

def export_obj

    print "ObjExport\n\n"
    print "Written by Alex Williams\n"
    print "http://blinkenlights.ca\n\n"

    if( file_path = UI.savepanel "Export to .obj", "~", "sketch.obj") then
        if( file_path[-4..-1].eql? ".obj" )
            file_path = file_path[0..-5]
        end

        vertex_list = Array.new
        normal_list = Array.new
        uv_list = Array.new
        index_list = Array.new
        material_list = Array.new

        build_geometry( vertex_list, normal_list, uv_list, index_list, material_list );
        write_geometry( file_path, vertex_list, normal_list, uv_list, index_list, material_list );
    end
end

UI.menu("Plugins").add_item("Export to .obj") { export_obj }