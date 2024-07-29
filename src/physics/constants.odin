package physics

import "core:math/linalg"

DELTA_TIME :: 0.01



@private
GRAVITATIONAL_ACCELERATION :: 10

get_gravitational_pull :: proc(location : vec3) -> vec3 {
	/*
	Todo(Leo): once the rough size of the body is decided, calculate gravity
	constant etc to a good value so that intended effect on surface is achieved
	and then this can be computed to be varying depending on height of the location etc.
	*/
	// For now, assume constant magnitude towards center
	return linalg.normalize(-location) * GRAVITATIONAL_ACCELERATION
}