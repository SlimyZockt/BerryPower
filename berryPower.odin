package main

import "core:log"
import "core:os"

main :: proc() {
	LOG_PATH :: ".logs"
	if !os.exists(LOG_PATH) {
	}
	handle, err := os.open(LOG_PATH, flags = os.O_RDWR)

	ensure(err == nil)

	context.logger = log.create_multi_logger(
		log.create_file_logger(handle),
		log.create_console_logger(),
	)


	log.debug("main")

}
