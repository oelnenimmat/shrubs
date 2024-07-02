/*
This file is intended for temporary solutions for problems that
need immediate solving but proper solutions are not available at
the time. As we gather temp solutions to this single place, they
are easy to locate in later times and can be solved properly when
the correct solution makes itself apparent. By doing this, we can
make the usage code work as intended and solve the underlying
problem at better time, but also it is not lost and forgotten, but
stored here.

Consider everything in this file as "todo, please do me better".

Please, prefix things with TEMP_ and leave a Todo(Name): comment shortly
describing the issue.
*/

package game

import "shrubs:assets"
import "shrubs:graphics"
import "shrubs:physics"

// Todo(Leo): I do not think assets package should own the memory, as
// there might be cases where we want to keep the the mesh info on CPU
// ram after uploading it into GPU ram.  
TEMP_load_mesh_gltf :: proc(mesh_file_name, mesh_node_name : cstring) -> graphics.Mesh {
	positions, normals, elements := assets.NOT_MEMORY_SAFE_gltf_load_node(mesh_file_name, mesh_node_name)
	mesh := graphics.create_mesh(positions, normals, nil, elements)

	delete(positions)
	delete(normals)
	delete(elements)

	return mesh
}

// Todo(Leo): similar to TEMP_load_mesh_gltf
TEMP_load_color_texture :: proc(filename : cstring) -> graphics.Texture {
	image := assets.load_color_image(filename)
	defer assets.free_loaded_color_image(&image)
	texture := graphics.create_color_texture(
		image.width,
		image.height,
		image.pixels,
		.Linear,
	)
	return texture
}

TEMP_ColliderTag :: enum { None = 0, Tank }
