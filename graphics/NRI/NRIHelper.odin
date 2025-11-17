// © 2021 NVIDIA Corporation

// Goal: utilities
package nri

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib"}
}


NRI_HELPER_H :: 1

NriVideoMemoryInfo :: struct {
	budgetSize: u64, // the OS-provided video memory budget. If "usageSize" > "budgetSize", the application may incur stuttering or performance penalties
	usageSize:  u64, // specifies the application’s current video memory usage
}

NriTextureSubresourceUploadDesc :: struct {
	slices:     rawptr,
	sliceNum:   u32,
	rowPitch:   u32,
	slicePitch: u32,
}

NriTextureUploadDesc :: struct {
	subresources: ^NriTextureSubresourceUploadDesc, // if provided, must include ALL subresources = layerNum * mipNum
	texture:      ^NriTexture,
	after:        NriAccessLayoutStage,
	planes:       NriPlaneBits,
}

NriBufferUploadDesc :: struct {
	data:   rawptr, // if provided, must be data for the whole buffer
	buffer: ^NriBuffer,
	after:  NriAccessStage,
}

NriResourceGroupDesc :: struct {
	memoryLocation:      NriMemoryLocation,
	textures:            ^^NriTexture,
	textureNum:          u32,
	buffers:             ^^NriBuffer,
	bufferNum:           u32,
	preferredMemorySize: u64, // desired chunk size (but can be greater if a resource doesn't fit), 256 Mb if 0
}

NriFormatProps :: struct {
	name:         cstring,   // format name
	format:       NriFormat, // self
	redBits:      u8,        // R (or depth) bits
	greenBits:    u8,        // G (or stencil) bits (0 if channels < 2)
	blueBits:     u8,        // B bits (0 if channels < 3)
	alphaBits:    u8,        // A (or shared exponent) bits (0 if channels < 4)
	stride:       u32,       // block size in bytes
	blockWidth:   u32,       // 1 for plain formats, >1 for compressed
	blockHeight:  u32,       // 1 for plain formats, >1 for compressed
	isBgr:        u32,       // reversed channels (RGBA => BGRA)
	isCompressed: u32,       // block-compressed format
	isDepth:      u32,       // has depth component
	isExpShared:  u32,       // shared exponent in alpha channel
	isFloat:      u32,       // floating point
	isPacked:     u32,       // 16- or 32- bit packed
	isInteger:    u32,       // integer
	isNorm:       u32,       // [0; 1] normalized
	isSigned:     u32,       // signed
	isSrgb:       u32,       // sRGB
	isStencil:    u32,       // has stencil component
	unused:       u32,
}

// Threadsafe: yes
NriHelperInterface :: struct {
	// Optimized memory allocation for a group of resources
	CalculateAllocationNumber: proc "c" (device: ^NriDevice, resourceGroupDesc: ^NriResourceGroupDesc) -> u32,
	AllocateAndBindMemory:     proc "c" (device: ^NriDevice, resourceGroupDesc: ^NriResourceGroupDesc, allocations: ^^NriMemory) -> NriResult, // "allocations" must have entries >= returned by "CalculateAllocationNumber"

	// Populate resources with data (not for streaming!)
	UploadData: proc "c" (queue: ^NriQueue, textureUploadDescs: ^NriTextureUploadDesc, textureUploadDescNum: u32, bufferUploadDescs: ^NriBufferUploadDesc, bufferUploadDescNum: u32) -> NriResult,

	// Information about video memory
	QueryVideoMemoryInfo: proc "c" (device: ^NriDevice, memoryLocation: NriMemoryLocation, videoMemoryInfo: ^NriVideoMemoryInfo) -> NriResult,
}

@(default_calling_convention="c")
foreign lib {
	// Format utilities
	nriConvertDXGIFormatToNRI :: proc(dxgiFormat: u32) -> NriFormat --- // returns best-matched typed format for "TYPELESS"
	nriConvertVKFormatToNRI   :: proc(vkFormat: u32) -> NriFormat ---
	nriConvertNRIFormatToDXGI :: proc(format: NriFormat) -> u32 ---
	nriConvertNRIFormatToVK   :: proc(format: NriFormat) -> u32 ---
	nriGetFormatProps         :: proc(format: NriFormat) -> ^NriFormatProps ---

	// Strings
	nriGetGraphicsAPIString :: proc(graphicsAPI: NriGraphicsAPI) -> cstring ---
}

// A convinient way to fit pipeline layout settings into the device limits, respecting various restrictions
NriPipelineLayoutSettingsDesc :: struct {
	descriptorSetNum:                   u32,
	descriptorRangeNum:                 u32,
	rootConstantSize:                   u32,
	rootDescriptorNum:                  u32,
	preferRootDescriptorsOverConstants: bool,
	enableD3D12DrawParametersEmulation: bool, // not needed for VK, unsupported in D3D11
}

