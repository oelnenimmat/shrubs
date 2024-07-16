package game

import "shrubs:graphics"
import "shrubs:assets"

/*
Todo(Leo): these are for now stored as numeric values in scene file,
which means that is the order is shuffled, or items are removed from
in between, those indices are going to point to wrong assets. So, for
the time being, only add to end, and if need to remove, rename the 
removed asset to "__removed_N" instead. New names can then be assigned
to those when required.
*/
TextureAssetName :: enum {
	White,
	Black,

	Green_Grass_Field,
	Blue_Grass_Field,
	Grass_Placement,
	Rock,
	Road,
	Wind,
}

/*
Todo(Leo): these are for now stored as numeric values in scene file,
which means that is the order is shuffled, or items are removed from
in between, those indices are going to point to wrong assets. So, for
the time being, only add to end, and if need to remove, rename the 
removed asset to "__removed_N" instead. New names can then be assigned
to those when required.
*/
MeshAssetName :: enum {
	Capsule,
	Cube,
	Quad,

	Tank_Body,
	Tank_Wheel,
}

asset_provider : struct {
	textures : [TextureAssetName]graphics.Texture,
	meshes : [MeshAssetName]graphics.Mesh,
}

load_asset_provider :: proc() {
	asset_provider = {}

	///////////////////////////////////////////////////////////////////////////
	// Load Textures
	// Todo(Leo): for now it is super extra fine to have these hardcoded. Maybe
	// later is better if these are read from a file or smth

	asset_provider.textures = [TextureAssetName]graphics.Texture {
		.White = graphics.create_color_texture(1, 1, []u8{255, 255, 255, 255}, .Nearest),
		.Black = graphics.create_color_texture(1, 1, []u8{0, 0, 0, 255}, .Nearest),

		.Green_Grass_Field 	= load_color_texture("assets/callum_andrews_ghibli_grass.png"),
		.Blue_Grass_Field 	= load_color_texture("assets/blue_grass.png"),
		.Grass_Placement 	= load_color_texture("assets/grass_placement_test.png", .Nearest),
		.Rock 				= load_color_texture("assets/rock_01_diff_4k.jpg"),
		.Road 				= load_color_texture("assets/rocky_trail_diff_4k.jpg"),

		// http://kitfox.com/projects/perlinNoiseMaker/
		.Wind 				= load_color_texture("assets/perlin_wind.png"),
	}

	///////////////////////////////////////////////////////////////////////////
	// Load Meshes

	asset_provider.meshes = [MeshAssetName]graphics.Mesh {
		.Capsule 	= load_mesh_gltf("assets/shapes.glb", "shape_capsule"),
		.Cube 		= load_mesh_gltf("assets/shapes.glb", "shape_cube"),
		.Quad 		= load_mesh_gltf("assets/shapes.glb", "shape_quad"),

		.Tank_Body = load_mesh_gltf("assets/tank.glb", "tank_body"),
		.Tank_Wheel = load_mesh_gltf("assets/tank.glb", "tank_wheel"),
	}
}

unload_asset_provider :: proc() {
	for texture in &asset_provider.textures {
		graphics.destroy_texture(&texture)
	}

	for mesh in &asset_provider.meshes {
		graphics.destroy_mesh(&mesh)
	}
}

// Todo(Leo): I do not think assets package should own the memory, as
// there might be cases where we want to keep the the mesh info on CPU
// ram after uploading it into GPU ram. 
@(private = "file")
load_mesh_gltf :: proc(mesh_file_name, mesh_node_name : cstring) -> graphics.Mesh {
	positions, normals, texcoords, elements := assets.NOT_MEMORY_SAFE_gltf_load_node(mesh_file_name, mesh_node_name)
	mesh := graphics.create_mesh(positions, normals, texcoords, elements)

	delete(positions)
	delete(normals)
	delete(texcoords)
	delete(elements)

	return mesh
}

// Todo(Leo): similar to load_mesh_gltf
@(private = "file")
load_color_texture :: proc(filename : cstring, filter_mode := graphics.TextureFilterMode.Linear) -> graphics.Texture {
	image := assets.load_color_image(filename)
	defer assets.free_loaded_color_image(&image)
	texture := graphics.create_color_texture(
		image.width,
		image.height,
		image.pixels_u8_rgba,
		filter_mode,
	)
	return texture
}
