package nri

import nri "./nri_lib/"
import "core:log"
import vmem "core:mem/virtual"

GetQueueFrameNum :: 3

main :: proc() {
	context.logger = log.create_console_logger()

	global_arena: vmem.Arena
	err := vmem.arena_init_growing(&global_arena)
	ensure(err == .None)

	context.allocator = vmem.arena_allocator(&global_arena)

	adapter_count: u32
	res := nri.EnumerateAdapters(nil, &adapter_count)
	ensure(res == .SUCCESS)

	adapters := make([dynamic]nri.AdapterDesc, len = adapter_count)
	res = nri.EnumerateAdapters(raw_data(adapters), &adapter_count)
	ensure(res == .SUCCESS)

	device_creation_desc: nri.DeviceCreationDesc
	device_creation_desc.graphicsAPI = .VK
	device_creation_desc.enableNRIValidation = true
	device_creation_desc.enableGraphicsAPIValidation = true
	device_creation_desc.enableMemoryZeroInitialization = true

	device: ^nri.Device
	res = nri.CreateDevice(&device_creation_desc, &device)
	ensure(res == .SUCCESS)

	NriInterface :: struct {
		using _: nri.CoreInterface,
		using _: nri.HelperInterface,
		using _: nri.LowLatencyInterface,
		using _: nri.MeshShaderInterface,
		using _: nri.RayTracingInterface,
		using _: nri.StreamerInterface,
		using _: nri.SwapChainInterface,
		using _: nri.UpscalerInterface,
	}

	interface: NriInterface

	nri.GetInterface(
		device,
		"CoreInterface",
		size_of(nri.CoreInterface),
		cast(^nri.CoreInterface)&interface,
	)

	nri.GetInterface(
		device,
		"HelperInterface",
		size_of(nri.HelperInterface),
		cast(^nri.HelperInterface)&interface,
	)

	nri.GetInterface(
		device,
		"StreamerInterface",
		size_of(nri.StreamerInterface),
		cast(^nri.StreamerInterface)&interface,
	)

	nri.GetInterface(
		device,
		"SwapChainInterface",
		size_of(nri.SwapChainInterface),
		cast(^nri.SwapChainInterface)&interface,
	)

	streamer_desc: nri.StreamerDesc
	streamer_desc.dynamicBufferMemoryLocation = .HOST_UPLOAD
	streamer_desc.dynamicBufferDesc = nri.BufferDesc{0, 0, {.VERTEX_BUFFER, .INDEX_BUFFER}}
	streamer_desc.constantBufferMemoryLocation = .HOST_UPLOAD
	// TODO: Implement GetQueue()
	streamer_desc.queuedFrameNum = GetQueueFrameNum

	nri.Raser


}
