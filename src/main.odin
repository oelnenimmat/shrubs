/*
Entry point and main loop for the game. Package game
will do all stuff basically, this merely starts the program and tracks
time.
*/
package main

import "core:fmt"
import "core:time"
import "core:math"
import "core:os"

import "game"

main :: proc() {

	// SETUP
	// ------------------------------------------------------------------
	game.initialize()

	frame_start_time 	:= time.now()
	delta_time 			:= 0.0

	main_loop: for {

		// UPDATE APPLICATION
		// -------------------------------------------------
		
		game.update(delta_time)
		game.render()

		if game.does_want_to_quit() { break main_loop }

		// TRACK TIME
		// ---------------------------------------------------------

		frame_end_time 	:= time.now()
		delta_time 		= time.duration_seconds(
			time.diff(frame_start_time, frame_end_time))
		
		limit_fps :: false
		when limit_fps {
			// todo(Leo): hacktrick! Limit frame rate to 30 FPS to add delay between 
			// frames while we still not have proper cpu-gpu synchronization
			max_fps :: 60
			target_time :: 1.0 / max_fps
			time_to_wait_ms := int((target_time - delta_time) * 1000)

			if time_to_wait_ms > 1 {
				time.sleep(time.Millisecond * time.Duration(time_to_wait_ms))

				// More time has passed, recalculate
				frame_end_time = time.now()
				delta_time = time.duration_seconds(
					time.diff(frame_start_time, frame_end_time))
			}
		}

		frame_start_time = frame_end_time
	}
	
	// CLEANUP
	// ----------------------------------------------------------------

	game.terminate()
	fmt.println("All good!")


}
