/*
As described by
https://catlikecoding.com/unity/tutorials/pseudorandom-noise/hashing/

read that more carefully for extra cpu-optimization hints and other stuff
this is a very quick implementation for very limited and try-outty use case
*/

package common

PRIME_A : u32 : 2654435761 //0b10011110001101110111100110110001
PRIME_B : u32 : 2246822519 //0b10000101111010111100101001110111
PRIME_C : u32 : 3266489917 //0b11000010101100101010111000111101
PRIME_D : u32 : 668265263 //0b00100111110101001110101100101111
PRIME_E : u32 : 374761393 //0b00010110010101100110011110110001

SmallXXHash :: struct {
	accumulator : u32,
}

small_xx_hash_make :: proc(seed : i32) -> SmallXXHash {
	return { u32(seed) + PRIME_E }
}

small_xx_hash_eat :: proc(hash : SmallXXHash, data : i32) -> SmallXXHash {
	return { rotate_left(hash.accumulator + u32(data) * PRIME_C, 17) * PRIME_D }
}

small_xx_hash_get_u32 :: proc(hash : SmallXXHash) -> u32 {
	avalanche := hash.accumulator
	avalanche ~= avalanche >> 15
	avalanche *= PRIME_B
	avalanche ~= avalanche >> 13
	avalanche *= PRIME_C
	avalanche ~= avalanche >> 16
	return avalanche
}

small_xx_hash_get_f32_0_to_1 :: proc(hash : SmallXXHash) -> f32 {
	return f32(small_xx_hash_get_u32(hash)) / 4294967295.0 //f32(max(u32))
}

rotate_left :: #force_inline proc(data : u32, steps : u32) -> u32 {
	return (data << steps) | (data >> (32 - steps))
}