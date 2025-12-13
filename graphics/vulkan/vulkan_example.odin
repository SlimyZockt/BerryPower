package main

import "base:runtime"
import "core:c"
import "core:log"
import vmem "core:mem/virtual"
import "core:slice"
import glfw "vendor:glfw"
import vk "vendor:vulkan"

ENABLE_VALIDATION_LAYERS :: #config(ENABLE_VALIDATION_LAYERS, ODIN_DEBUG)

APP_VERSION := vk.MAKE_VERSION(1, 0, 0)
ENGINE_VERSION := vk.MAKE_VERSION(1, 0, 0)


g_context: runtime.Context
g_framebuffer_resized: bool

g_arena: vmem.Arena

main :: proc() {
	context.logger = log.create_console_logger()
	g_context = context


	ensure(vmem.arena_init_growing(&g_arena) == .None)
	allocators: vk.AllocationCallbacks
	instance: vk.Instance
	surface: vk.SurfaceKHR

	when ENABLE_VALIDATION_LAYERS {
		dbg_msg: vk.DebugUtilsMessengerEXT
	}

	window_handel: glfw.WindowHandle
	{ 	// Init window
		ensure(glfw.Init() == true)

		glfw.SetErrorCallback(proc "c" (error: c.int, description: cstring) {
			context = g_context
			log.errorf("[gltw] [%i] %s", error, description)
		})

		glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
		glfw.WindowHint(glfw.RESIZABLE, glfw.FALSE)


		window_handel = glfw.CreateWindow(800, 600, "Vulkan", nil, nil)
		ensure(window_handel != nil)

		glfw.SetFramebufferSizeCallback(
			window_handel,
			proc "c" (window: glfw.WindowHandle, width, height: c.int) {
				g_framebuffer_resized = true
			},
		)

		vk.load_proc_addresses_global(rawptr(glfw.GetInstanceProcAddress))
		assert(vk.CreateInstance != nil, "[vulkan] function pointers not loaded")
	}
	defer { 	// Cleanup window
		glfw.DestroyWindow(window_handel)
		glfw.Terminate()
	}

	{ 	// Init Vulkan
		app_info: vk.ApplicationInfo
		app_info.sType = .APPLICATION_INFO
		app_info.pApplicationName = "Berry Engine"
		app_info.pEngineName = "No Engine"
		app_info.applicationVersion = APP_VERSION
		app_info.engineVersion = ENGINE_VERSION
		app_info.apiVersion = vk.API_VERSION_1_0

		extentions := slice.clone_to_dynamic(
			glfw.GetRequiredInstanceExtensions(),
			context.allocator,
		)
		log.debug(extentions)

		create_info: vk.InstanceCreateInfo
		create_info.sType = .INSTANCE_CREATE_INFO
		create_info.pApplicationInfo = &app_info

		when ENABLE_VALIDATION_LAYERS {
			create_info.ppEnabledLayerNames = raw_data([]cstring{"VK_LAYER_KHRONOS_validation"})
			create_info.enabledLayerCount = 1

			append(&extentions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)

			severity: vk.DebugUtilsMessageSeverityFlagsEXT
			if context.logger.lowest_level <= .Error {
				severity |= {.ERROR}
			}
			if context.logger.lowest_level <= .Warning {
				severity |= {.WARNING}
			}
			if context.logger.lowest_level <= .Info {
				severity |= {.INFO}
			}
			if context.logger.lowest_level <= .Debug {
				severity |= {.VERBOSE}
			}

			dbg_create_info := vk.DebugUtilsMessengerCreateInfoEXT {
				sType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
				messageSeverity = severity,
				messageType = {.GENERAL, .VALIDATION, .PERFORMANCE, .DEVICE_ADDRESS_BINDING}, // all of them.
				pfnUserCallback = proc "system" (
					messageSeverity: vk.DebugUtilsMessageSeverityFlagsEXT,
					messageTypes: vk.DebugUtilsMessageTypeFlagsEXT,
					pCallbackData: ^vk.DebugUtilsMessengerCallbackDataEXT,
					pUserData: rawptr,
				) -> b32 {
					context = g_context

					level: log.Level
					if .ERROR in messageSeverity {
						level = .Error
					} else if .WARNING in messageSeverity {
						level = .Warning
					} else if .INFO in messageSeverity {
						level = .Info
					} else {
						level = .Debug
					}

					log.logf(level, "[vulkan] [%v] %s", messageTypes, pCallbackData.pMessage)
					return false
				},
			}

			create_info.pNext = &dbg_create_info
		}

		create_info.enabledExtensionCount = cast(u32)len(extentions)
		create_info.ppEnabledExtensionNames = raw_data(extentions)

		ensure(vk.CreateInstance(&create_info, nil, &instance) == .SUCCESS)

		vk.load_proc_addresses_instance(instance)

		when ENABLE_VALIDATION_LAYERS {
			ensure(
				vk.CreateDebugUtilsMessengerEXT(instance, &dbg_create_info, nil, &dbg_msg) ==
				.SUCCESS,
			)
		}

		ensure(glfw.CreateWindowSurface(instance, window_handel, nil, &surface) == .SUCCESS)

        { // Pick Gpu

        }
	}

	defer { 	// Cleanup Vulkan
		vk.DestroyInstance(instance, nil)

		when ENABLE_VALIDATION_LAYERS {
			vk.DestroyDebugUtilsMessengerEXT(instance, dbg_msg, nil)
		}
		vk.DestroySurfaceKHR(instance, surface, nil)
	}

	log.info("[GLTW] Main Loop")
	{ 	// Main Loop
		for (!glfw.WindowShouldClose(window_handel)) {
			glfw.PollEvents()


		}
	}

}
