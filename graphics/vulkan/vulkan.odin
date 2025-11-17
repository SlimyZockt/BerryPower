package main

import "core:log"
import vk "vendor:vulkan"

main :: proc() {
	context.logger = log.create_console_logger()
	log.info("Vulkan")
}
