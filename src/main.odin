/*
Entry point and main loop for the application. Package application
will do all stuff basically, this merely starts the program and tracks
time.
*/
package main

import "core:fmt"
import "core:time"
import "core:math"
import "core:os"

import "application"

main :: proc() {

	// arguments := application.parse_command_line_arguments()
	// if error, is_error := arguments.(application.ArgumentParseError); is_error {
	// 	fmt.printf("ERROR: %s\n", error.explanation)
	// 	return
	// }

	// SETUP
	// ------------------------------------------------------------------
	application.initialize()

	frame_start_time 	:= time.now()
	delta_time 			:= 0.0

	for {

		// UPDATE APPLICATION
		// -------------------------------------------------
		
		application.update(delta_time)

		if application.does_want_to_quit() {
			break;
		}

		// TRACK TIME
		// ---------------------------------------------------------

		frame_end_time 	:= time.now()
		delta_time 		= time.duration_seconds(
			time.diff(frame_start_time, frame_end_time))
		
		limit_fps :: true
		when limit_fps {
			// todo(Leo): hacktrick! Limit frame rate to 30 FPS to add delay between 
			// frames while we still not have proper cpu-gpu synchronization
			max_fps :: 20
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

	application.terminate()
	fmt.println("All good!")


}
