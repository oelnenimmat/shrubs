//+private
package application

import "../graphics"

Assets :: struct {
	gradient_textures : [3]graphics.Texture,
}

create_assets :: proc() -> Assets {
	using a : Assets
	
	gradient_textures[0] = graphics.create_gradient_texture(gradient_0.colors, gradient_0.positions)
	gradient_textures[1] = graphics.create_gradient_texture(gradient_1.colors, gradient_1.positions)
	gradient_textures[2] = graphics.create_gradient_texture(gradient_2.colors, gradient_2.positions)

	return a
}

destroy_assets :: proc(using a : ^Assets) {
	for g in gradient_textures {
		graphics.destroy_texture(g)
	}
}

GradientDescription :: struct {
	colors 		: []vec4,
	positions 	: []f32,
}

gradient_0 :: GradientDescription {
	colors = {
		{0.5, 0, 1, 1},
		{0, 0.8, 0.9, 1},
		{1, 1, 0, 1},
	},

	positions = {0, 0.5, 1}
}

gradient_1 :: GradientDescription {
	colors = {
		{1, 1, 0, 1},
		{0, 0.8, 0.9, 1},
		{0.5, 0, 1, 1},
	},

	positions = {0, 0.5, 1}
}

gradient_2 :: GradientDescription {
	colors = {
		{0.631, 0.004, 0.180, 1},
		{0.804, 0.475, 0.565, 1},
		{1,1,1,1},
		{0.616, 0.447, 0.741, 1},
		{0.305, 0, 0.529, 1},
	},

	positions = {0, 0.4, 0.5, 0.6, 1}
}
