// const uint PRIME_A = 2654435761;
// const uint PRIME_B = 2246822519;
// const uint PRIME_C = 3266489917;
// const uint PRIME_D = 668265263;
// const uint PRIME_E = 374761393;

// // struct SmallXXHash {
// // 	uint accumulator;
// // };

// uint small_xx_hash_make (int seed) {
// 	return uint(seed) + PRIME_E;
// }

// uint rotate_left(uint data, uint steps) {
// 	return (data << steps) | (data >> (32 - steps));
// }

// uint small_xx_hash_eat (uint hash, int data) {
// 	return rotate_left(hash + uint(data) * PRIME_C, 17) * PRIME_D;
// }

// uint small_xx_hash_get_uint (uint hash) {
// 	uint avalanche = hash;
// 	avalanche = avalanche ^ (avalanche >> 15);
// 	avalanche *= PRIME_B;
// 	avalanche = avalanche ^ (avalanche >> 13);
// 	avalanche *= PRIME_C;
// 	avalanche = avalanche ^ (avalanche >> 16);
// 	return avalanche;
// }

// float small_xx_hash_get_float (uint hash) {
// 	return float(small_xx_hash_get_uint(hash)) / 4294967295.0;
// }

// float value_noise_2D(float x, float y) {
// 	int ix0 = int(floor(x));
// 	int ix1 = ix0 + 1;
// 	float tx = smoothstep(0, 1, x - ix0);

// 	int iy0 = int(floor(y));
// 	int iy1 = iy0 + 1;
// 	float ty = smoothstep(0, 1, y - iy0);

// 	uint h0 = small_xx_hash_make(ix0);
// 	uint h1 = small_xx_hash_make(ix1);

// 	uint h00 = small_xx_hash_eat(h0, iy0);
// 	uint h10 = small_xx_hash_eat(h1, iy0);
// 	uint h01 = small_xx_hash_eat(h0, iy1);
// 	uint h11 = small_xx_hash_eat(h1, iy1);

// 	float v00 = small_xx_hash_get_float(h00);
// 	float v10 = small_xx_hash_get_float(h10);
// 	float v01 = small_xx_hash_get_float(h01);
// 	float v11 = small_xx_hash_get_float(h11);

// 	float v0 = mix(v00, v10, tx);
// 	float v1 = mix(v01, v11, tx);

// 	float v = mix(v0, v1, ty);

// 	return v;
// }
