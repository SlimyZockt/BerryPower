// © 2021 NVIDIA Corporation

// Goal: ray tracing
// https://microsoft.github.io/DirectX-Specs/d3d/Raytracing.html
package nri

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib"}
}


NRI_RAY_TRACING_H :: 1

NriAccelerationStructure :: struct {} // bottom- or top- level acceleration structure (aka BLAS or TLAS respectively)
NriMicromap              :: struct {} // a micromap that encodes sub-triangle opacity (aka OMM, can be attached to a triangle BLAS)

//============================================================================================================================================================================================
NriRayTracingPipelineBits :: u8

//============================================================================================================================================================================================
NriRayTracingPipelineBits_ :: enum u32 {
	//============================================================================================================================================================================================
	NONE            = 0,

	//============================================================================================================================================================================================
	SKIP_TRIANGLES  = 1,

	//============================================================================================================================================================================================
	SKIP_AABBS      = 2,

	//============================================================================================================================================================================================
	ALLOW_MICROMAPS = 4,
}

NriShaderLibraryDesc :: struct {
	shaders:   ^NriShaderDesc,
	shaderNum: u32,
}

NriShaderGroupDesc :: struct {
	// Use cases:
	//  - general: RAYGEN_SHADER, MISS_SHADER or CALLABLE_SHADER
	//  - HitGroup: CLOSEST_HIT_SHADER and/or ANY_HIT_SHADER in any order
	//  - HitGroup with an intersection shader: INTERSECTION_SHADER + CLOSEST_HIT_SHADER and/or ANY_HIT_SHADER in any order
	shaderIndices: [3]u32, // in ShaderLibrary, starting from 1 (0 - unused)
}

NriRayTracingPipelineDesc :: struct {
	pipelineLayout:         ^NriPipelineLayout,
	shaderLibrary:          ^NriShaderLibraryDesc,
	shaderGroups:           ^NriShaderGroupDesc,
	shaderGroupNum:         u32,
	recursionMaxDepth:      u32,
	rayPayloadMaxSize:      u32,
	rayHitAttributeMaxSize: u32,
	flags:                  NriRayTracingPipelineBits,
	robustness:             NriRobustness,
}

//============================================================================================================================================================================================
NriMicromapFormat_ :: enum u32 {
	//============================================================================================================================================================================================
	OPACITY_2_STATE = 1,

	//============================================================================================================================================================================================
	OPACITY_4_STATE = 2,

	//============================================================================================================================================================================================
	MAX_NUM         = 3,
}

//============================================================================================================================================================================================
NriMicromapFormat :: u16

NriMicromapSpecialIndex_ :: enum i32 {
	FULLY_TRANSPARENT         = -1,
	FULLY_OPAQUE              = -2,
	FULLY_UNKNOWN_TRANSPARENT = -3,
	FULLY_UNKNOWN_OPAQUE      = -4,
	MAX_NUM                   = -3,
}

NriMicromapSpecialIndex :: i8
NriMicromapBits         :: u8

NriMicromapBits_ :: enum u32 {
	NONE              = 0,
	ALLOW_COMPACTION  = 2,
	PREFER_FAST_TRACE = 4,
	PREFER_FAST_BUILD = 8,
}

NriMicromapUsageDesc :: struct {
	triangleNum:      u32, // represents "MicromapTriangle" number for "{format, subdivisionLevel}" pair contained in the micromap
	subdivisionLevel: u16, // micro triangles count = 4 ^ subdivisionLevel
	format:           NriMicromapFormat,
}

NriMicromapDesc :: struct {
	optimizedSize: u64, // can be retrieved by "CmdWriteMicromapsSizes" and used for compaction via "CmdCopyMicromap"
	usages:        ^NriMicromapUsageDesc,
	usageNum:      u32,
	flags:         NriMicromapBits,
}

NriBindMicromapMemoryDesc :: struct {
	micromap: ^NriMicromap,
	memory:   ^NriMemory,
	offset:   u64,
}

NriBuildMicromapDesc :: struct {
	dst:            ^NriMicromap,
	dataBuffer:     ^NriBuffer,
	dataOffset:     u64,
	triangleBuffer: ^NriBuffer, // contains "MicromapTriangle" entries
	triangleOffset: u64,
	scratchBuffer:  ^NriBuffer,
	scratchOffset:  u64,
}

NriBottomLevelMicromapDesc :: struct {
	// For each triangle in the geometry, the acceleration structure build fetches an index from "indexBuffer".
	// If an index is the unsigned cast of one of the values from "MicromapSpecialIndex" then that triangle behaves as described for that special value.
	// Otherwise that triangle uses the micromap information from "micromap" at that index plus "baseTriangle".
	// If an index buffer is not provided, "1:1" mapping between geometry triangles and micromap triangles is assumed.
	micromap:     ^NriMicromap,
	indexBuffer:  ^NriBuffer,
	indexOffset:  u64,
	baseTriangle: u32,
	indexType:    NriIndexType,
}

// Data layout
NriMicromapTriangle :: struct {
	dataOffset:       u32,
	subdivisionLevel: u16,
	format:           NriMicromapFormat,
}

//============================================================================================================================================================================================
NriBottomLevelGeometryType :: u8

//============================================================================================================================================================================================
NriBottomLevelGeometryType_ :: enum u32 {
	//============================================================================================================================================================================================
	TRIANGLES = 0,

	//============================================================================================================================================================================================
	AABBS     = 1,

	//============================================================================================================================================================================================
	MAX_NUM   = 2,
}

NriBottomLevelGeometryBits :: u8

NriBottomLevelGeometryBits_ :: enum u32 {
	NONE                            = 0,
	OPAQUE_GEOMETRY                 = 1,
	NO_DUPLICATE_ANY_HIT_INVOCATION = 2,
}

NriBottomLevelTrianglesDesc :: struct {
	// Vertices
	vertexBuffer: ^NriBuffer,
	vertexOffset: u64,
	vertexNum:    u32,
	vertexStride: u16,
	vertexFormat: NriFormat,

	// Indices
	indexBuffer: ^NriBuffer,
	indexOffset: u64,
	indexNum:    u32,
	indexType:   NriIndexType,

	// Transform
	transformBuffer: ^NriBuffer, // contains "TransformMatrix" entries
	transformOffset: u64,

	// Micromap
	micromap: ^NriBottomLevelMicromapDesc,
}

NriBottomLevelAabbsDesc :: struct {
	buffer: ^NriBuffer, // contains "BottomLevelAabb" entries
	offset: u64,
	num:    u32,
	stride: u32,
}

NriBottomLevelGeometryDesc :: struct {
	flags: NriBottomLevelGeometryBits,
	type:  NriBottomLevelGeometryType,

	using _: struct #raw_union {
		triangles: NriBottomLevelTrianglesDesc,
		aabbs:     NriBottomLevelAabbsDesc,
	},
}

// Data layout
NriTransformMatrix :: struct {
	transform: [3][4]f32, // 3x4 row-major affine transformation matrix, the first three columns of matrix must define an invertible 3x3 matrix
}

NriBottomLevelAabb :: struct {
	minX: f32,
	minY: f32,
	minZ: f32,
	maxX: f32,
	maxY: f32,
	maxZ: f32,
}

//============================================================================================================================================================================================
NriTopLevelInstanceBits :: u32

//============================================================================================================================================================================================
NriTopLevelInstanceBits_ :: enum u32 {
	//============================================================================================================================================================================================
	NONE                  = 0,

	//============================================================================================================================================================================================
	TRIANGLE_CULL_DISABLE = 1,

	//============================================================================================================================================================================================
	TRIANGLE_FLIP_FACING  = 2,

	//============================================================================================================================================================================================
	FORCE_OPAQUE          = 4,

	//============================================================================================================================================================================================
	FORCE_NON_OPAQUE      = 8,

	//============================================================================================================================================================================================
	FORCE_OPACITY_2_STATE = 16,

	//============================================================================================================================================================================================
	DISABLE_MICROMAPS     = 32,
}

NriTopLevelInstance :: struct {
	transform:                     [3][4]f32,
	instanceId:                    u32,
	mask:                          u32,
	shaderBindingTableLocalOffset: u32,
	flags:                         NriTopLevelInstanceBits,
	accelerationStructureHandle:   u64,
}

//============================================================================================================================================================================================
NriAccelerationStructureType_ :: enum u32 {
	//============================================================================================================================================================================================
	TOP_LEVEL    = 0,

	//============================================================================================================================================================================================
	BOTTOM_LEVEL = 1,

	//============================================================================================================================================================================================
	MAX_NUM      = 2,
}

//============================================================================================================================================================================================
NriAccelerationStructureType :: u8
NriAccelerationStructureBits :: u8

NriAccelerationStructureBits_ :: enum u32 {
	NONE                    = 0,
	ALLOW_UPDATE            = 1,
	ALLOW_COMPACTION        = 2,
	ALLOW_DATA_ACCESS       = 4,
	ALLOW_MICROMAP_UPDATE   = 8,
	ALLOW_DISABLE_MICROMAPS = 16,
	PREFER_FAST_TRACE       = 32,
	PREFER_FAST_BUILD       = 64,
	MINIMIZE_MEMORY         = 128,
}

NriAccelerationStructureDesc :: struct {
	optimizedSize:         u64,                         // can be retrieved by "CmdWriteAccelerationStructuresSizes" and used for compaction via "CmdCopyAccelerationStructure"
	geometries:            ^NriBottomLevelGeometryDesc, // needed only for "BOTTOM_LEVEL", "HAS_BUFFER" can be used to indicate a buffer presence (no real entities needed at initialization time)
	geometryOrInstanceNum: u32,
	flags:                 NriAccelerationStructureBits,
	type:                  NriAccelerationStructureType,
}

NriBindAccelerationStructureMemoryDesc :: struct {
	accelerationStructure: ^NriAccelerationStructure,
	memory:                ^NriMemory,
	offset:                u64,
}

NriBuildTopLevelAccelerationStructureDesc :: struct {
	dst:            ^NriAccelerationStructure,
	src:            ^NriAccelerationStructure, // implies "update" instead of "build" if provided (requires "ALLOW_UPDATE")
	instanceNum:    u32,
	instanceBuffer: ^NriBuffer,                // contains "TopLevelInstance" entries
	instanceOffset: u64,
	scratchBuffer:  ^NriBuffer,                // use "GetAccelerationStructureBuildScratchBufferSize" or "GetAccelerationStructureUpdateScratchBufferSize" to determine the required size
	scratchOffset:  u64,
}

NriBuildBottomLevelAccelerationStructureDesc :: struct {
	dst:           ^NriAccelerationStructure,
	src:           ^NriAccelerationStructure, // implies "update" instead of "build" if provided (requires "ALLOW_UPDATE")
	geometries:    ^NriBottomLevelGeometryDesc,
	geometryNum:   u32,
	scratchBuffer: ^NriBuffer,
	scratchOffset: u64,
}

//============================================================================================================================================================================================
NriCopyMode_ :: enum u32 {
	//============================================================================================================================================================================================
	CLONE   = 0,

	//============================================================================================================================================================================================
	COMPACT = 1,

	//============================================================================================================================================================================================
	MAX_NUM = 2,
}

//============================================================================================================================================================================================
NriCopyMode :: u8

NriStridedBufferRegion :: struct {
	buffer: ^NriBuffer,
	offset: u64,
	size:   u64,
	stride: u64,
}

NriDispatchRaysDesc :: struct {
	raygenShader:    NriStridedBufferRegion,
	missShaders:     NriStridedBufferRegion,
	hitShaderGroups: NriStridedBufferRegion,
	callableShaders: NriStridedBufferRegion,
	x, y, z:         u32,
}

NriDispatchRaysIndirectDesc :: struct {
	raygenShaderRecordAddress:         u64,
	raygenShaderRecordSize:            u64,
	missShaderBindingTableAddress:     u64,
	missShaderBindingTableSize:        u64,
	missShaderBindingTableStride:      u64,
	hitShaderBindingTableAddress:      u64,
	hitShaderBindingTableSize:         u64,
	hitShaderBindingTableStride:       u64,
	callableShaderBindingTableAddress: u64,
	callableShaderBindingTableSize:    u64,
	callableShaderBindingTableStride:  u64,
	x, y, z:                           u32,
}

// Threadsafe: yes
NriRayTracingInterface :: struct {
	// Create
	CreateRayTracingPipeline:              proc "c" (device: ^NriDevice, rayTracingPipelineDesc: ^NriRayTracingPipelineDesc, pipeline: ^^NriPipeline) -> NriResult,
	CreateAccelerationStructureDescriptor: proc "c" (accelerationStructure: ^NriAccelerationStructure, descriptor: ^^NriDescriptor) -> NriResult,

	// Get
	GetAccelerationStructureHandle:                  proc "c" (accelerationStructure: ^NriAccelerationStructure) -> u64,
	GetAccelerationStructureUpdateScratchBufferSize: proc "c" (accelerationStructure: ^NriAccelerationStructure) -> u64,
	GetAccelerationStructureBuildScratchBufferSize:  proc "c" (accelerationStructure: ^NriAccelerationStructure) -> u64,
	GetMicromapBuildScratchBufferSize:               proc "c" (micromap: ^NriMicromap) -> u64,

	// For barriers
	GetAccelerationStructureBuffer: proc "c" (accelerationStructure: ^NriAccelerationStructure) -> ^NriBuffer,
	GetMicromapBuffer:              proc "c" (micromap: ^NriMicromap) -> ^NriBuffer,

	// Destroy
	DestroyAccelerationStructure: proc "c" (accelerationStructure: ^NriAccelerationStructure),
	DestroyMicromap:              proc "c" (micromap: ^NriMicromap),

	// Resources and memory (VK style)
	CreateAccelerationStructure:        proc "c" (device: ^NriDevice, accelerationStructureDesc: ^NriAccelerationStructureDesc, accelerationStructure: ^^NriAccelerationStructure) -> NriResult,
	CreateMicromap:                     proc "c" (device: ^NriDevice, micromapDesc: ^NriMicromapDesc, micromap: ^^NriMicromap) -> NriResult,
	GetAccelerationStructureMemoryDesc: proc "c" (accelerationStructure: ^NriAccelerationStructure, memoryLocation: NriMemoryLocation, memoryDesc: ^NriMemoryDesc),
	GetMicromapMemoryDesc:              proc "c" (micromap: ^NriMicromap, memoryLocation: NriMemoryLocation, memoryDesc: ^NriMemoryDesc),
	BindAccelerationStructureMemory:    proc "c" (bindAccelerationStructureMemoryDescs: ^NriBindAccelerationStructureMemoryDesc, bindAccelerationStructureMemoryDescNum: u32) -> NriResult,
	BindMicromapMemory:                 proc "c" (bindMicromapMemoryDescs: ^NriBindMicromapMemoryDesc, bindMicromapMemoryDescNum: u32) -> NriResult,

	// Resources and memory (D3D12 style)
	GetAccelerationStructureMemoryDesc2:  proc "c" (device: ^NriDevice, accelerationStructureDesc: ^NriAccelerationStructureDesc, memoryLocation: NriMemoryLocation, memoryDesc: ^NriMemoryDesc), // requires "features.getMemoryDesc2"
	GetMicromapMemoryDesc2:               proc "c" (device: ^NriDevice, micromapDesc: ^NriMicromapDesc, memoryLocation: NriMemoryLocation, memoryDesc: ^NriMemoryDesc), // requires "features.getMemoryDesc2"
	CreateCommittedAccelerationStructure: proc "c" (device: ^NriDevice, memoryLocation: NriMemoryLocation, priority: f32, accelerationStructureDesc: ^NriAccelerationStructureDesc, accelerationStructure: ^^NriAccelerationStructure) -> NriResult,
	CreateCommittedMicromap:              proc "c" (device: ^NriDevice, memoryLocation: NriMemoryLocation, priority: f32, micromapDesc: ^NriMicromapDesc, micromap: ^^NriMicromap) -> NriResult,
	CreatePlacedAccelerationStructure:    proc "c" (device: ^NriDevice, memory: ^NriMemory, offset: u64, accelerationStructureDesc: ^NriAccelerationStructureDesc, accelerationStructure: ^^NriAccelerationStructure) -> NriResult,
	CreatePlacedMicromap:                 proc "c" (device: ^NriDevice, memory: ^NriMemory, offset: u64, micromapDesc: ^NriMicromapDesc, micromap: ^^NriMicromap) -> NriResult,

	// Shader table
	// "dst" size must be >= "shaderGroupNum * rayTracingShaderGroupIdentifierSize" bytes
	// VK doesn't have a "local root signature" analog, thus stride = "rayTracingShaderGroupIdentifierSize", i.e. tight packing
	WriteShaderGroupIdentifiers: proc "c" (pipeline: ^NriPipeline, baseShaderGroupIndex: u32, shaderGroupNum: u32, dst: rawptr) -> NriResult,

	// Command buffer
	// {
	// Micromap
	CmdBuildMicromaps:      proc "c" (commandBuffer: ^NriCommandBuffer, buildMicromapDescs: ^NriBuildMicromapDesc, buildMicromapDescNum: u32),
	CmdWriteMicromapsSizes: proc "c" (commandBuffer: ^NriCommandBuffer, micromaps: ^^NriMicromap, micromapNum: u32, queryPool: ^NriQueryPool, queryPoolOffset: u32),
	CmdCopyMicromap:        proc "c" (commandBuffer: ^NriCommandBuffer, dst: ^NriMicromap, src: ^NriMicromap, copyMode: NriCopyMode),

	// Acceleration structure
	CmdBuildTopLevelAccelerationStructures:    proc "c" (commandBuffer: ^NriCommandBuffer, buildTopLevelAccelerationStructureDescs: ^NriBuildTopLevelAccelerationStructureDesc, buildTopLevelAccelerationStructureDescNum: u32),
	CmdBuildBottomLevelAccelerationStructures: proc "c" (commandBuffer: ^NriCommandBuffer, buildBotomLevelAccelerationStructureDescs: ^NriBuildBottomLevelAccelerationStructureDesc, buildBotomLevelAccelerationStructureDescNum: u32),
	CmdWriteAccelerationStructuresSizes:       proc "c" (commandBuffer: ^NriCommandBuffer, accelerationStructures: ^^NriAccelerationStructure, accelerationStructureNum: u32, queryPool: ^NriQueryPool, queryPoolOffset: u32),
	CmdCopyAccelerationStructure:              proc "c" (commandBuffer: ^NriCommandBuffer, dst: ^NriAccelerationStructure, src: ^NriAccelerationStructure, copyMode: NriCopyMode),

	// Ray tracing
	CmdDispatchRays:         proc "c" (commandBuffer: ^NriCommandBuffer, dispatchRaysDesc: ^NriDispatchRaysDesc),
	CmdDispatchRaysIndirect: proc "c" (commandBuffer: ^NriCommandBuffer, buffer: ^NriBuffer, offset: u64), // buffer contains "DispatchRaysIndirectDesc" commands

	// }
	
	// Native object
	GetAccelerationStructureNativeObject: proc "c" (accelerationStructure: ^NriAccelerationStructure) -> u64, // ID3D12Resource* or VkAccelerationStructureKHR
	GetMicromapNativeObject:              proc "c" (micromap: ^NriMicromap) -> u64,                           // ID3D12Resource* or VkMicromapEXT
}

