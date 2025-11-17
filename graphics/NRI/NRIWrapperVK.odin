// © 2021 NVIDIA Corporation

// Goal: wrapping native VK objects into NRI objects
package nri

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib"}
}


NRI_WRAPPER_VK_H :: 1

VKHandle                :: rawptr
VKEnum                  :: i32
VKFlags                 :: u32
VKNonDispatchableHandle :: u64

// A collection of queues of the same type
NriQueueFamilyVKDesc :: struct {
	queueNum:    u32,
	queueType:   NriQueueType,
	familyIndex: u32,
}

NriDeviceCreationVKDesc :: struct {
	callbackInterface:   NriCallbackInterface,
	allocationCallbacks: NriAllocationCallbacks,
	libraryPath:         cstring,
	vkBindingOffsets:    NriVKBindingOffsets,
	vkExtensions:        NriVKExtensions, // enabled
	vkInstance:          VKHandle,
	vkDevice:            VKHandle,
	vkPhysicalDevice:    VKHandle,
	queueFamilies:       ^NriQueueFamilyVKDesc,
	queueFamilyNum:      u32,
	minorVersion:        u8,              // >= 2

	// Switches (disabled by default)
	enableNRIValidation:            bool,
	enableMemoryZeroInitialization: bool, // page-clears are fast, but memory is not cleared by default in VK
}

NriCommandAllocatorVKDesc :: struct {
	vkCommandPool: VKNonDispatchableHandle,
	queueType:     NriQueueType,
}

NriCommandBufferVKDesc :: struct {
	vkCommandBuffer: VKHandle,
	queueType:       NriQueueType,
}

NriDescriptorPoolVKDesc :: struct {
	vkDescriptorPool:    VKNonDispatchableHandle,
	descriptorSetMaxNum: u32,
}

NriBufferVKDesc :: struct {
	vkBuffer:        VKNonDispatchableHandle,
	size:            u64,
	structureStride: u32,                     // must be provided if used as a structured or raw buffer
	mappedMemory:    ^u8,                     // must be provided if the underlying memory is mapped
	vkDeviceMemory:  VKNonDispatchableHandle, // must be provided *only* if the mapped memory exists and *not* HOST_COHERENT
	deviceAddress:   u64,                     // must be provided for ray tracing
}

NriTextureVKDesc :: struct {
	vkImage:     VKNonDispatchableHandle,
	vkFormat:    VKEnum,
	vkImageType: VKEnum,
	width:       NriDim_t,
	height:      NriDim_t,
	depth:       NriDim_t,
	mipNum:      NriDim_t,
	layerNum:    NriDim_t,
	sampleNum:   NriSample_t,
}

NriMemoryVKDesc :: struct {
	vkDeviceMemory:  VKNonDispatchableHandle,
	offset:          u64,
	mappedMemory:    rawptr, // at "offset"
	size:            u64,
	memoryTypeIndex: u32,
}

NriPipelineVKDesc :: struct {
	vkPipeline:          VKNonDispatchableHandle,
	vkPipelineBindPoint: VKEnum,
}

NriQueryPoolVKDesc :: struct {
	vkQueryPool: VKNonDispatchableHandle,
	vkQueryType: VKEnum,
}

NriFenceVKDesc :: struct {
	vkTimelineSemaphore: VKNonDispatchableHandle,
}

NriAccelerationStructureVKDesc :: struct {
	vkAccelerationStructure: VKNonDispatchableHandle,
	vkBuffer:                VKNonDispatchableHandle,
	bufferSize:              u64,
	buildScratchSize:        u64,
	updateScratchSize:       u64,
	flags:                   NriAccelerationStructureBits,
}

// Threadsafe: yes
NriWrapperVKInterface :: struct {
	CreateCommandAllocatorVK:      proc "c" (device: ^NriDevice, commandAllocatorVKDesc: ^NriCommandAllocatorVKDesc, commandAllocator: ^^NriCommandAllocator) -> NriResult,
	CreateCommandBufferVK:         proc "c" (device: ^NriDevice, commandBufferVKDesc: ^NriCommandBufferVKDesc, commandBuffer: ^^NriCommandBuffer) -> NriResult,
	CreateDescriptorPoolVK:        proc "c" (device: ^NriDevice, descriptorPoolVKDesc: ^NriDescriptorPoolVKDesc, descriptorPool: ^^NriDescriptorPool) -> NriResult,
	CreateBufferVK:                proc "c" (device: ^NriDevice, bufferVKDesc: ^NriBufferVKDesc, buffer: ^^NriBuffer) -> NriResult,
	CreateTextureVK:               proc "c" (device: ^NriDevice, textureVKDesc: ^NriTextureVKDesc, texture: ^^NriTexture) -> NriResult,
	CreateMemoryVK:                proc "c" (device: ^NriDevice, memoryVKDesc: ^NriMemoryVKDesc, memory: ^^NriMemory) -> NriResult,
	CreatePipelineVK:              proc "c" (device: ^NriDevice, pipelineVKDesc: ^NriPipelineVKDesc, pipeline: ^^NriPipeline) -> NriResult,
	CreateQueryPoolVK:             proc "c" (device: ^NriDevice, queryPoolVKDesc: ^NriQueryPoolVKDesc, queryPool: ^^NriQueryPool) -> NriResult,
	CreateFenceVK:                 proc "c" (device: ^NriDevice, fenceVKDesc: ^NriFenceVKDesc, fence: ^^NriFence) -> NriResult,
	CreateAccelerationStructureVK: proc "c" (device: ^NriDevice, accelerationStructureVKDesc: ^NriAccelerationStructureVKDesc, accelerationStructure: ^^NriAccelerationStructure) -> NriResult,
	GetQueueFamilyIndexVK:         proc "c" (queue: ^NriQueue) -> u32,
	GetPhysicalDeviceVK:           proc "c" (device: ^NriDevice) -> VKHandle,
	GetInstanceVK:                 proc "c" (device: ^NriDevice) -> VKHandle,
	GetInstanceProcAddrVK:         proc "c" (device: ^NriDevice) -> rawptr,
	GetDeviceProcAddrVK:           proc "c" (device: ^NriDevice) -> rawptr,
}

@(default_calling_convention="c")
foreign lib {
	nriCreateDeviceFromVKDevice :: proc(deviceDesc: ^NriDeviceCreationVKDesc, device: ^^NriDevice) -> NriResult ---
}

