// © 2021 NVIDIA Corporation

// Goal: wrapping native VK objects into NRI objects
package nri_lib

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib", "system:stdc++"}
}


NRI_WRAPPER_VK_H :: 1

VKHandle                :: rawptr
VKEnum                  :: i32
VKFlags                 :: u32
VKNonDispatchableHandle :: u64

// A collection of queues of the same type
QueueFamilyVKDesc :: struct {
	queueNum:    u32,
	queueType:   QueueType,
	familyIndex: u32,
}

DeviceCreationVKDesc :: struct {
	callbackInterface:   CallbackInterface,
	allocationCallbacks: AllocationCallbacks,
	libraryPath:         cstring,
	vkBindingOffsets:    VKBindingOffsets,
	vkExtensions:        VKExtensions, // enabled
	vkInstance:          VKHandle,
	vkDevice:            VKHandle,
	vkPhysicalDevice:    VKHandle,
	queueFamilies:       ^QueueFamilyVKDesc,
	queueFamilyNum:      u32,
	minorVersion:        u8,           // >= 2

	// Switches (disabled by default)
	enableNRIValidation:            bool,
	enableMemoryZeroInitialization: bool, // page-clears are fast, but memory is not cleared by default in VK
}

CommandAllocatorVKDesc :: struct {
	vkCommandPool: VKNonDispatchableHandle,
	queueType:     QueueType,
}

CommandBufferVKDesc :: struct {
	vkCommandBuffer: VKHandle,
	queueType:       QueueType,
}

DescriptorPoolVKDesc :: struct {
	vkDescriptorPool:    VKNonDispatchableHandle,
	descriptorSetMaxNum: u32,
}

BufferVKDesc :: struct {
	vkBuffer:        VKNonDispatchableHandle,
	size:            u64,
	structureStride: u32,                     // must be provided if used as a structured or raw buffer
	mappedMemory:    ^u8,                     // must be provided if the underlying memory is mapped
	vkDeviceMemory:  VKNonDispatchableHandle, // must be provided *only* if the mapped memory exists and *not* HOST_COHERENT
	deviceAddress:   u64,                     // must be provided for ray tracing
}

TextureVKDesc :: struct {
	vkImage:     VKNonDispatchableHandle,
	vkFormat:    VKEnum,
	vkImageType: VKEnum,
	width:       Dim_t,
	height:      Dim_t,
	depth:       Dim_t,
	mipNum:      Dim_t,
	layerNum:    Dim_t,
	sampleNum:   Sample_t,
}

MemoryVKDesc :: struct {
	vkDeviceMemory:  VKNonDispatchableHandle,
	offset:          u64,
	mappedMemory:    rawptr, // at "offset"
	size:            u64,
	memoryTypeIndex: u32,
}

PipelineVKDesc :: struct {
	vkPipeline:          VKNonDispatchableHandle,
	vkPipelineBindPoint: VKEnum,
}

QueryPoolVKDesc :: struct {
	vkQueryPool: VKNonDispatchableHandle,
	vkQueryType: VKEnum,
}

FenceVKDesc :: struct {
	vkTimelineSemaphore: VKNonDispatchableHandle,
}

AccelerationStructureVKDesc :: struct {
	vkAccelerationStructure: VKNonDispatchableHandle,
	vkBuffer:                VKNonDispatchableHandle,
	bufferSize:              u64,
	buildScratchSize:        u64,
	updateScratchSize:       u64,
	flags:                   AccelerationStructureBits,
}

// Threadsafe: yes
WrapperVKInterface :: struct {
	CreateCommandAllocatorVK:      proc "c" (device: ^Device, commandAllocatorVKDesc: ^CommandAllocatorVKDesc, commandAllocator: ^^CommandAllocator) -> Result,
	CreateCommandBufferVK:         proc "c" (device: ^Device, commandBufferVKDesc: ^CommandBufferVKDesc, commandBuffer: ^^CommandBuffer) -> Result,
	CreateDescriptorPoolVK:        proc "c" (device: ^Device, descriptorPoolVKDesc: ^DescriptorPoolVKDesc, descriptorPool: ^^DescriptorPool) -> Result,
	CreateBufferVK:                proc "c" (device: ^Device, bufferVKDesc: ^BufferVKDesc, buffer: ^^Buffer) -> Result,
	CreateTextureVK:               proc "c" (device: ^Device, textureVKDesc: ^TextureVKDesc, texture: ^^Texture) -> Result,
	CreateMemoryVK:                proc "c" (device: ^Device, memoryVKDesc: ^MemoryVKDesc, memory: ^^Memory) -> Result,
	CreatePipelineVK:              proc "c" (device: ^Device, pipelineVKDesc: ^PipelineVKDesc, pipeline: ^^Pipeline) -> Result,
	CreateQueryPoolVK:             proc "c" (device: ^Device, queryPoolVKDesc: ^QueryPoolVKDesc, queryPool: ^^QueryPool) -> Result,
	CreateFenceVK:                 proc "c" (device: ^Device, fenceVKDesc: ^FenceVKDesc, fence: ^^Fence) -> Result,
	CreateAccelerationStructureVK: proc "c" (device: ^Device, accelerationStructureVKDesc: ^AccelerationStructureVKDesc, accelerationStructure: ^^AccelerationStructure) -> Result,
	GetQueueFamilyIndexVK:         proc "c" (queue: ^Queue) -> u32,
	GetPhysicalDeviceVK:           proc "c" (device: ^Device) -> VKHandle,
	GetInstanceVK:                 proc "c" (device: ^Device) -> VKHandle,
	GetInstanceProcAddrVK:         proc "c" (device: ^Device) -> rawptr,
	GetDeviceProcAddrVK:           proc "c" (device: ^Device) -> rawptr,
}

@(default_calling_convention="c", link_prefix="nri")
foreign lib {
	CreateDeviceFromVKDevice :: proc(deviceDesc: ^DeviceCreationVKDesc, device: ^^Device) -> Result ---
}

