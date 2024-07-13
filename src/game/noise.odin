package game

import "core:math"
import "core:math/linalg"

value_noise_2D :: proc(x, y : f32, seed : i32) -> f32 {
	ix0 := i32(math.floor(x))
	ix1 := ix0 + 1
	tx 	:= math.smoothstep(f32(0), f32(1), x - f32(ix0))

	iy0 := i32(math.floor(y))
	iy1 := iy0 + 1
	ty 	:= math.smoothstep(f32(0), f32(1), y - f32(iy0))

	h := small_xx_hash_make(seed)

	// hX
	h0 := small_xx_hash_eat	(h, ix0)
	h1 := small_xx_hash_eat	(h, ix1)

	// hXY
	h00 := small_xx_hash_eat(h0, iy0)
	h10 := small_xx_hash_eat(h1, iy0)
	h01 := small_xx_hash_eat(h0, iy1)
	h11 := small_xx_hash_eat(h1, iy1)

	// vXY
	v00 := small_xx_hash_get_f32_0_to_1(h00)
	v10 := small_xx_hash_get_f32_0_to_1(h10)
	v01 := small_xx_hash_get_f32_0_to_1(h01)
	v11 := small_xx_hash_get_f32_0_to_1(h11)
	
	// vY
	v0 := linalg.lerp(v00, v10, tx)
	v1 := linalg.lerp(v01, v11, tx)

	v := linalg.lerp(v0, v1, ty)

	return v
}