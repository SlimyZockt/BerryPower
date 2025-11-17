// © 2021 NVIDIA Corporation

/*
Overview:
- Generalized common denominator for VK, D3D12 and D3D11
    - VK spec: https://registry.khronos.org/vulkan/specs/latest/html/vkspec.html
       - Best practices: https://developer.nvidia.com/blog/vulkan-dos-donts/
       - Feature support coverage: https://vulkan.gpuinfo.org/
    - D3D12 spec: https://microsoft.github.io/DirectX-Specs/
       - Feature support coverage: https://d3d12infodb.boolka.dev/
    - D3D11 spec: https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm

Goals:
- generalization and unification of D3D12 and VK
- explicitness (providing access to low-level features of modern GAPIs)
- quality-of-life and high-level extensions (e.g., streaming and upscaling)
- low overhead
- cross-platform and platform independence (AMD/INTEL friendly)
- D3D11 support (as much as possible)

Non-goals:
- exposing entities not existing in GAPIs
- high-level (D3D11-like) abstraction
- hidden management of any kind (except for some high-level extensions where it's desired)
- automatic barriers (better handled in a higher-level abstraction)

Thread safety:
- Threadsafe: yes - free-threaded access
- Threadsafe: no  - external synchronization required, i.e. one thread at a time (additional restrictions can apply)
- Threadsafe: ?   - unclear status

Implicit:
- Create*         - thread safe
- Destroy*        - not thread safe (because of VK)
- Cmd*            - not thread safe
*/
package nri

import "core:c"

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib"}
}


NRI_VERSION      :: 176
NRI_VERSION_DATE :: "21 October 2025"

@(default_calling_convention="c")
foreign lib {
	// Example: Result result = nriGetInterface(device, NRI_INTERFACE(CoreInterface), &coreInterface)
	nriGetInterface :: proc(device: ^NriDevice, interfaceName: cstring, interfaceSize: c.size_t, interfacePtr: rawptr) -> NriResult ---

	// Annotations for profiling tools: host
	// - Host annotations currently use NVTX (NVIDIA Nsight Systems)
	// - Device (command buffer and queue) annotations use GAPI or PIX (if "WinPixEventRuntime.dll" is nearby)
	// - Colorization requires PIX or NVTX
	nriBeginAnnotation :: proc(name: cstring, bgra: u32) --- // start a named range
	nriEndAnnotation   :: proc() ---                         // end the last opened range
	nriAnnotation      :: proc(name: cstring, bgra: u32) --- // emit a named simultaneous event
	nriSetThreadName   :: proc(name: cstring) ---            // assign a name to the current thread
}

// Threadsafe: yes
NriCoreInterface :: struct {
	// Get
	GetDeviceDesc:    proc "c" (device: ^NriDevice) -> ^NriDeviceDesc,
	GetBufferDesc:    proc "c" (buffer: ^NriBuffer) -> ^NriBufferDesc,
	GetTextureDesc:   proc "c" (texture: ^NriTexture) -> ^NriTextureDesc,
	GetFormatSupport: proc "c" (device: ^NriDevice, format: NriFormat) -> NriFormatSupportBits,
	GetQuerySize:     proc "c" (queryPool: ^NriQueryPool) -> u32,
	GetFenceValue:    proc "c" (fence: ^NriFence) -> u64,

	// Returns one of the pre-created queues (see "DeviceCreationDesc" or wrapper extensions)
	// Return codes: "UNSUPPORTED" (no queues of "queueType") or "INVALID_ARGUMENT" (if "queueIndex" is out of bounds).
	// Getting "COMPUTE" and/or "COPY" queues switches VK sharing mode to "VK_SHARING_MODE_CONCURRENT" for resources created without "queueExclusive" flag.
	// This approach is used to minimize number of "queue ownership transfers", but also adds a requirement to "get" all async queues BEFORE creation of
	// resources participating into multi-queue activities. Explicit use of "queueExclusive" removes any restrictions.
	GetQueue: proc "c" (device: ^NriDevice, queueType: NriQueueType, queueIndex: u32, queue: ^^NriQueue) -> NriResult,

	// Create (doesn't assume allocation of big chunks of memory on the device, but it happens for some entities implicitly)
	CreateCommandAllocator: proc "c" (queue: ^NriQueue, commandAllocator: ^^NriCommandAllocator) -> NriResult,
	CreateCommandBuffer:    proc "c" (commandAllocator: ^NriCommandAllocator, commandBuffer: ^^NriCommandBuffer) -> NriResult,
	CreateFence:            proc "c" (device: ^NriDevice, initialValue: u64, fence: ^^NriFence) -> NriResult,
	CreateDescriptorPool:   proc "c" (device: ^NriDevice, descriptorPoolDesc: ^NriDescriptorPoolDesc, descriptorPool: ^^NriDescriptorPool) -> NriResult,
	CreatePipelineLayout:   proc "c" (device: ^NriDevice, pipelineLayoutDesc: ^NriPipelineLayoutDesc, pipelineLayout: ^^NriPipelineLayout) -> NriResult,
	CreateGraphicsPipeline: proc "c" (device: ^NriDevice, graphicsPipelineDesc: ^NriGraphicsPipelineDesc, pipeline: ^^NriPipeline) -> NriResult,
	CreateComputePipeline:  proc "c" (device: ^NriDevice, computePipelineDesc: ^NriComputePipelineDesc, pipeline: ^^NriPipeline) -> NriResult,
	CreateQueryPool:        proc "c" (device: ^NriDevice, queryPoolDesc: ^NriQueryPoolDesc, queryPool: ^^NriQueryPool) -> NriResult,
	CreateSampler:          proc "c" (device: ^NriDevice, samplerDesc: ^NriSamplerDesc, sampler: ^^NriDescriptor) -> NriResult,
	CreateBufferView:       proc "c" (bufferViewDesc: ^NriBufferViewDesc, bufferView: ^^NriDescriptor) -> NriResult,
	CreateTexture1DView:    proc "c" (textureViewDesc: ^NriTexture1DViewDesc, textureView: ^^NriDescriptor) -> NriResult,
	CreateTexture2DView:    proc "c" (textureViewDesc: ^NriTexture2DViewDesc, textureView: ^^NriDescriptor) -> NriResult,
	CreateTexture3DView:    proc "c" (textureViewDesc: ^NriTexture3DViewDesc, textureView: ^^NriDescriptor) -> NriResult,

	// Destroy
	DestroyCommandAllocator: proc "c" (commandAllocator: ^NriCommandAllocator),
	DestroyCommandBuffer:    proc "c" (commandBuffer: ^NriCommandBuffer),
	DestroyDescriptorPool:   proc "c" (descriptorPool: ^NriDescriptorPool),
	DestroyBuffer:           proc "c" (buffer: ^NriBuffer),
	DestroyTexture:          proc "c" (texture: ^NriTexture),
	DestroyDescriptor:       proc "c" (descriptor: ^NriDescriptor),
	DestroyPipelineLayout:   proc "c" (pipelineLayout: ^NriPipelineLayout),
	DestroyPipeline:         proc "c" (pipeline: ^NriPipeline),
	DestroyQueryPool:        proc "c" (queryPool: ^NriQueryPool),
	DestroyFence:            proc "c" (fence: ^NriFence),

	// Memory
	AllocateMemory: proc "c" (device: ^NriDevice, allocateMemoryDesc: ^NriAllocateMemoryDesc, memory: ^^NriMemory) -> NriResult,
	FreeMemory:     proc "c" (memory: ^NriMemory),

	// Resources and memory (VK style)
	//  - create a resource (buffer or texture)
	//  - use "Get[Resource]MemoryDesc" to get "MemoryDesc" ("usageBits" and "MemoryLocation" affect returned "MemoryType")
	//  - (optional) group returned "MemoryDesc"s by "MemoryType", but don't group if "mustBeDedicated = true"
	//  - (optional) sort returned "MemoryDesc"s by alignment
	//  - call "AllocateMemory" (even if "mustBeDedicated = true")
	//  - call "Bind[Resource]Memory" to bind resources to "Memory" objects
	//  - (optional) "CalculateAllocationNumber" and "AllocateAndBindMemory" from "NRIHelper" interface simplify this process for buffers and textures
	CreateBuffer:         proc "c" (device: ^NriDevice, bufferDesc: ^NriBufferDesc, buffer: ^^NriBuffer) -> NriResult,
	CreateTexture:        proc "c" (device: ^NriDevice, textureDesc: ^NriTextureDesc, texture: ^^NriTexture) -> NriResult,
	GetBufferMemoryDesc:  proc "c" (buffer: ^NriBuffer, memoryLocation: NriMemoryLocation, memoryDesc: ^NriMemoryDesc),
	GetTextureMemoryDesc: proc "c" (texture: ^NriTexture, memoryLocation: NriMemoryLocation, memoryDesc: ^NriMemoryDesc),
	BindBufferMemory:     proc "c" (bindBufferMemoryDescs: ^NriBindBufferMemoryDesc, bindBufferMemoryDescNum: u32) -> NriResult,
	BindTextureMemory:    proc "c" (bindTextureMemoryDescs: ^NriBindTextureMemoryDesc, bindTextureMemoryDescNum: u32) -> NriResult,

	// Resources and memory (D3D12 style)
	// - "Get[Resource]MemoryDesc2" requires "maintenance4" support on Vulkan
	// - "memory, offset" pair can be replaced with a "Nri[Device/DeviceUpload/HostUpload/HostReadback]Heap" macro to create a placed resource in the corresponding memory using VMA (AMD Virtual Memory Allocator) implicitly
	GetBufferMemoryDesc2:   proc "c" (device: ^NriDevice, bufferDesc: ^NriBufferDesc, memoryLocation: NriMemoryLocation, memoryDesc: ^NriMemoryDesc), // requires "features.getMemoryDesc2"
	GetTextureMemoryDesc2:  proc "c" (device: ^NriDevice, textureDesc: ^NriTextureDesc, memoryLocation: NriMemoryLocation, memoryDesc: ^NriMemoryDesc), // requires "features.getMemoryDesc2"
	CreateCommittedBuffer:  proc "c" (device: ^NriDevice, memoryLocation: NriMemoryLocation, priority: f32, bufferDesc: ^NriBufferDesc, buffer: ^^NriBuffer) -> NriResult,
	CreateCommittedTexture: proc "c" (device: ^NriDevice, memoryLocation: NriMemoryLocation, priority: f32, textureDesc: ^NriTextureDesc, texture: ^^NriTexture) -> NriResult,
	CreatePlacedBuffer:     proc "c" (device: ^NriDevice, memory: ^NriMemory, offset: u64, bufferDesc: ^NriBufferDesc, buffer: ^^NriBuffer) -> NriResult,
	CreatePlacedTexture:    proc "c" (device: ^NriDevice, memory: ^NriMemory, offset: u64, textureDesc: ^NriTextureDesc, texture: ^^NriTexture) -> NriResult,

	// Descriptor set management (entities don't require destroying)
	// - if "ALLOW_UPDATE_AFTER_SET" not used, descriptor sets (and data pointed to by descriptors) must be updated before "CmdSetDescriptorSet"
	// - if "ALLOW_UPDATE_AFTER_SET" used, descriptor sets (and data pointed to by descriptors) can be updated after "CmdSetDescriptorSet"
	// - "ResetDescriptorPool" resets the pool and and wipes out all allocated descriptor sets
	AllocateDescriptorSets: proc "c" (descriptorPool: ^NriDescriptorPool, pipelineLayout: ^NriPipelineLayout, setIndex: u32, descriptorSets: ^^NriDescriptorSet, instanceNum: u32, variableDescriptorNum: u32) -> NriResult,
	UpdateDescriptorRanges: proc "c" (updateDescriptorRangeDescs: ^NriUpdateDescriptorRangeDesc, updateDescriptorRangeDescNum: u32),
	CopyDescriptorRanges:   proc "c" (copyDescriptorRangeDescs: ^NriCopyDescriptorRangeDesc, copyDescriptorRangeDescNum: u32),
	ResetDescriptorPool:    proc "c" (descriptorPool: ^NriDescriptorPool),

	// Command buffer (one time submit)
	BeginCommandBuffer: proc "c" (commandBuffer: ^NriCommandBuffer, descriptorPool: ^NriDescriptorPool) -> NriResult,

	// {                {
	// Set descriptor pool (initially can be set via "BeginCommandBuffer")
	CmdSetDescriptorPool: proc "c" (commandBuffer: ^NriCommandBuffer, descriptorPool: ^NriDescriptorPool),

	// Resource binding (expect "CmdSetPipelineLayout" to be called first)
	CmdSetPipelineLayout: proc "c" (commandBuffer: ^NriCommandBuffer, bindPoint: NriBindPoint, pipelineLayout: ^NriPipelineLayout),
	CmdSetDescriptorSet:  proc "c" (commandBuffer: ^NriCommandBuffer, setDescriptorSetDesc: ^NriSetDescriptorSetDesc),
	CmdSetRootConstants:  proc "c" (commandBuffer: ^NriCommandBuffer, setRootConstantsDesc: ^NriSetRootConstantsDesc),
	CmdSetRootDescriptor: proc "c" (commandBuffer: ^NriCommandBuffer, setRootDescriptorDesc: ^NriSetRootDescriptorDesc),

	// Pipeline
	CmdSetPipeline: proc "c" (commandBuffer: ^NriCommandBuffer, pipeline: ^NriPipeline),

	// Barrier
	CmdBarrier: proc "c" (commandBuffer: ^NriCommandBuffer, barrierDesc: ^NriBarrierDesc),

	// Input assembly
	CmdSetIndexBuffer:   proc "c" (commandBuffer: ^NriCommandBuffer, buffer: ^NriBuffer, offset: u64, indexType: NriIndexType),
	CmdSetVertexBuffers: proc "c" (commandBuffer: ^NriCommandBuffer, baseSlot: u32, vertexBufferDescs: ^NriVertexBufferDesc, vertexBufferNum: u32),

	// Initial state
	CmdSetViewports: proc "c" (commandBuffer: ^NriCommandBuffer, viewports: ^NriViewport, viewportNum: u32),
	CmdSetScissors:  proc "c" (commandBuffer: ^NriCommandBuffer, rects: ^NriRect, rectNum: u32),

	// Initial state, if enabled in any pipeline used in this command buffer
	CmdSetStencilReference: proc "c" (commandBuffer: ^NriCommandBuffer, frontRef: u8, backRef: u8),            // "backRef" requires "features.independentFrontAndBackStencilReferenceAndMasks"
	CmdSetDepthBounds:      proc "c" (commandBuffer: ^NriCommandBuffer, boundsMin: f32, boundsMax: f32),       // requires "features.depthBoundsTest"
	CmdSetBlendConstants:   proc "c" (commandBuffer: ^NriCommandBuffer, color: ^NriColor32f),
	CmdSetSampleLocations:  proc "c" (commandBuffer: ^NriCommandBuffer, locations: ^NriSampleLocation, locationNum: NriSample_t, sampleNum: NriSample_t), // requires "tiers.sampleLocations != 0"
	CmdSetShadingRate:      proc "c" (commandBuffer: ^NriCommandBuffer, shadingRateDesc: ^NriShadingRateDesc), // requires "tiers.shadingRate != 0"

	// State override
	CmdSetDepthBias: proc "c" (commandBuffer: ^NriCommandBuffer, depthBiasDesc: ^NriDepthBiasDesc), // requires "features.dynamicDepthBias"

	// Graphics
	CmdBeginRendering: proc "c" (commandBuffer: ^NriCommandBuffer, attachmentsDesc: ^NriAttachmentsDesc),

	// {                {
	// Fast clear
	CmdClearAttachments: proc "c" (commandBuffer: ^NriCommandBuffer, clearDescs: ^NriClearDesc, clearDescNum: u32, rects: ^NriRect, rectNum: u32),

	// Draw
	CmdDraw:        proc "c" (commandBuffer: ^NriCommandBuffer, drawDesc: ^NriDrawDesc),
	CmdDrawIndexed: proc "c" (commandBuffer: ^NriCommandBuffer, drawIndexedDesc: ^NriDrawIndexedDesc),

	// Draw indirect:
	//  - drawNum = min(drawNum, countBuffer ? countBuffer[countBufferOffset] : INF)
	//  - see "Modified draw command signatures"
	CmdDrawIndirect:        proc "c" (commandBuffer: ^NriCommandBuffer, buffer: ^NriBuffer, offset: u64, drawNum: u32, stride: u32, countBuffer: ^NriBuffer, countBufferOffset: u64), // "buffer" contains "Draw(Base)Desc" commands
	CmdDrawIndexedIndirect: proc "c" (commandBuffer: ^NriCommandBuffer, buffer: ^NriBuffer, offset: u64, drawNum: u32, stride: u32, countBuffer: ^NriBuffer, countBufferOffset: u64), // "buffer" contains "DrawIndexed(Base)Desc" commands

	// }                }
	CmdEndRendering: proc "c" (commandBuffer: ^NriCommandBuffer),

	// Compute
	CmdDispatch:         proc "c" (commandBuffer: ^NriCommandBuffer, dispatchDesc: ^NriDispatchDesc),
	CmdDispatchIndirect: proc "c" (commandBuffer: ^NriCommandBuffer, buffer: ^NriBuffer, offset: u64), // buffer contains "DispatchDesc" commands

	// Copy
	CmdCopyBuffer:              proc "c" (commandBuffer: ^NriCommandBuffer, dstBuffer: ^NriBuffer, dstOffset: u64, srcBuffer: ^NriBuffer, srcOffset: u64, size: u64),
	CmdCopyTexture:             proc "c" (commandBuffer: ^NriCommandBuffer, dstTexture: ^NriTexture, dstRegion: ^NriTextureRegionDesc, srcTexture: ^NriTexture, srcRegion: ^NriTextureRegionDesc),
	CmdUploadBufferToTexture:   proc "c" (commandBuffer: ^NriCommandBuffer, dstTexture: ^NriTexture, dstRegion: ^NriTextureRegionDesc, srcBuffer: ^NriBuffer, srcDataLayout: ^NriTextureDataLayoutDesc),
	CmdReadbackTextureToBuffer: proc "c" (commandBuffer: ^NriCommandBuffer, dstBuffer: ^NriBuffer, dstDataLayout: ^NriTextureDataLayoutDesc, srcTexture: ^NriTexture, srcRegion: ^NriTextureRegionDesc),
	CmdZeroBuffer:              proc "c" (commandBuffer: ^NriCommandBuffer, buffer: ^NriBuffer, offset: u64, size: u64),

	// Resolve
	CmdResolveTexture: proc "c" (commandBuffer: ^NriCommandBuffer, dstTexture: ^NriTexture, dstRegion: ^NriTextureRegionDesc, srcTexture: ^NriTexture, srcRegion: ^NriTextureRegionDesc), // "features.regionResolve" is needed for region specification

	// Clear (potentially slow)
	CmdClearStorage: proc "c" (commandBuffer: ^NriCommandBuffer, clearDesc: ^NriClearStorageDesc),

	// Query
	CmdResetQueries: proc "c" (commandBuffer: ^NriCommandBuffer, queryPool: ^NriQueryPool, offset: u32, num: u32),
	CmdBeginQuery:   proc "c" (commandBuffer: ^NriCommandBuffer, queryPool: ^NriQueryPool, offset: u32),
	CmdEndQuery:     proc "c" (commandBuffer: ^NriCommandBuffer, queryPool: ^NriQueryPool, offset: u32),
	CmdCopyQueries:  proc "c" (commandBuffer: ^NriCommandBuffer, queryPool: ^NriQueryPool, offset: u32, num: u32, dstBuffer: ^NriBuffer, dstOffset: u64),

	// Annotations for profiling tools: command buffer
	CmdBeginAnnotation: proc "c" (commandBuffer: ^NriCommandBuffer, name: cstring, bgra: u32),
	CmdEndAnnotation:   proc "c" (commandBuffer: ^NriCommandBuffer),
	CmdAnnotation:      proc "c" (commandBuffer: ^NriCommandBuffer, name: cstring, bgra: u32),

	// }                }
	EndCommandBuffer: proc "c" (commandBuffer: ^NriCommandBuffer) -> NriResult, // D3D11 performs state tracking and resets it there

	// Annotations for profiling tools: command queue - D3D11: NOP
	QueueBeginAnnotation: proc "c" (queue: ^NriQueue, name: cstring, bgra: u32),
	QueueEndAnnotation:   proc "c" (queue: ^NriQueue),
	QueueAnnotation:      proc "c" (queue: ^NriQueue, name: cstring, bgra: u32),

	// Query
	ResetQueries: proc "c" (queryPool: ^NriQueryPool, offset: u32, num: u32), // on host

	// Work submission and synchronization
	QueueSubmit:    proc "c" (queue: ^NriQueue, queueSubmitDesc: ^NriQueueSubmitDesc) -> NriResult, // to device
	QueueWaitIdle:  proc "c" (queue: ^NriQueue) -> NriResult,
	DeviceWaitIdle: proc "c" (device: ^NriDevice) -> NriResult,
	Wait:           proc "c" (fence: ^NriFence, value: u64),                                        // on host

	// Command allocator
	ResetCommandAllocator: proc "c" (commandAllocator: ^NriCommandAllocator),

	// Map / Unmap
	// D3D11: no persistent mapping
	// D3D12: persistent mapping, "Map/Unmap" do nothing
	// VK: persistent mapping, but "Unmap" can do a flush if underlying memory is not "HOST_COHERENT" (unlikely)
	MapBuffer:   proc "c" (buffer: ^NriBuffer, offset: u64, size: u64) -> rawptr,
	UnmapBuffer: proc "c" (buffer: ^NriBuffer),

	// Debug name for any object declared as "NriForwardStruct" (skipped for buffers & textures in D3D if they are not bound to a memory)
	SetDebugName: proc "c" (object: ^NriObject, name: cstring),

	// Native objects                                                                                            ___D3D11 (latest interface)________|_D3D12 (latest interface)____|_VK_________________________________
	GetDeviceNativeObject:        proc "c" (device: ^NriDevice) -> rawptr,               // ID3D11Device*                   | ID3D12Device*               | VkDevice
	GetQueueNativeObject:         proc "c" (queue: ^NriQueue) -> rawptr,                 // -                               | ID3D12CommandQueue*         | VkQueue
	GetCommandBufferNativeObject: proc "c" (commandBuffer: ^NriCommandBuffer) -> rawptr, // ID3D11DeviceContext*            | ID3D12GraphicsCommandList*  | VkCommandBuffer
	GetBufferNativeObject:        proc "c" (buffer: ^NriBuffer) -> u64,                  // ID3D11Buffer*                   | ID3D12Resource*             | VkBuffer
	GetTextureNativeObject:       proc "c" (texture: ^NriTexture) -> u64,                // ID3D11Resource*                 | ID3D12Resource*             | VkImage
	GetDescriptorNativeObject:    proc "c" (descriptor: ^NriDescriptor) -> u64,          // ID3D11View/ID3D11SamplerState*  | D3D12_CPU_DESCRIPTOR_HANDLE | VkImageView/VkBufferView/VkSampler
}

