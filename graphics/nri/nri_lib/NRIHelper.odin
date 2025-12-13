// © 2021 NVIDIA Corporation

// Goal: utilities
package nri_lib

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib", "system:stdc++"}
}


NRI_HELPER_H :: 1

VideoMemoryInfo :: struct {
	budgetSize: u64, // the OS-provided video memory budget. If "usageSize" > "budgetSize", the application may incur stuttering or performance penalties
	usageSize:  u64, // specifies the application’s current video memory usage
}

TextureSubresourceUploadDesc :: struct {
	slices:     rawptr,
	sliceNum:   u32,
	rowPitch:   u32,
	slicePitch: u32,
}

TextureUploadDesc :: struct {
	subresources: ^TextureSubresourceUploadDesc, // if provided, must include ALL subresources = layerNum * mipNum
	texture:      ^Texture,
	after:        AccessLayoutStage,
	planes:       PlaneBits,
}

BufferUploadDesc :: struct {
	data:   rawptr, // if provided, must be data for the whole buffer
	buffer: ^Buffer,
	after:  AccessStage,
}

ResourceGroupDesc :: struct {
	memoryLocation:      MemoryLocation,
	textures:            ^^Texture,
	textureNum:          u32,
	buffers:             ^^Buffer,
	bufferNum:           u32,
	preferredMemorySize: u64, // desired chunk size (but can be greater if a resource doesn't fit), 256 Mb if 0
}

FormatProps :: struct {
	name:         cstring, // format name
	format:       Format,  // self
	redBits:      u8,      // R (or depth) bits
	greenBits:    u8,      // G (or stencil) bits (0 if channels < 2)
	blueBits:     u8,      // B bits (0 if channels < 3)
	alphaBits:    u8,      // A (or shared exponent) bits (0 if channels < 4)
	stride:       u32,     // block size in bytes
	blockWidth:   u32,     // 1 for plain formats, >1 for compressed
	blockHeight:  u32,     // 1 for plain formats, >1 for compressed
	isBgr:        u32,     // reversed channels (RGBA => BGRA)
	isCompressed: u32,     // block-compressed format
	isDepth:      u32,     // has depth component
	isExpShared:  u32,     // shared exponent in alpha channel
	isFloat:      u32,     // floating point
	isPacked:     u32,     // 16- or 32- bit packed
	isInteger:    u32,     // integer
	isNorm:       u32,     // [0; 1] normalized
	isSigned:     u32,     // signed
	isSrgb:       u32,     // sRGB
	isStencil:    u32,     // has stencil component
	unused:       u32,
}

// Threadsafe: yes
HelperInterface :: struct {
	// Optimized memory allocation for a group of resources
	CalculateAllocationNumber: proc "c" (device: ^Device, resourceGroupDesc: ^ResourceGroupDesc) -> u32,
	AllocateAndBindMemory:     proc "c" (device: ^Device, resourceGroupDesc: ^ResourceGroupDesc, allocations: ^^Memory) -> Result, // "allocations" must have entries >= returned by "CalculateAllocationNumber"

	// Populate resources with data (not for streaming!)
	UploadData: proc "c" (queue: ^Queue, textureUploadDescs: ^TextureUploadDesc, textureUploadDescNum: u32, bufferUploadDescs: ^BufferUploadDesc, bufferUploadDescNum: u32) -> Result,

	// Information about video memory
	QueryVideoMemoryInfo: proc "c" (device: ^Device, memoryLocation: MemoryLocation, videoMemoryInfo: ^VideoMemoryInfo) -> Result,
}

// A convinient way to fit pipeline layout settings into the device limits, respecting various restrictions
PipelineLayoutSettingsDesc :: struct {
	descriptorSetNum:                   u32,
	descriptorRangeNum:                 u32,
	rootConstantSize:                   u32,
	rootDescriptorNum:                  u32,
	preferRootDescriptorsOverConstants: bool,
	enableD3D12DrawParametersEmulation: bool, // not needed for VK, unsupported in D3D11
}

@(default_calling_convention="c", link_prefix="nri")
foreign lib {
	// Format utilities
	ConvertDXGIFormatToNRI :: proc(dxgiFormat: u32) -> Format --- // returns best-matched typed format for "TYPELESS"
	ConvertVKFormatToNRI   :: proc(vkFormat: u32) -> Format ---
	ConvertNRIFormatToDXGI :: proc(format: Format) -> u32 ---
	ConvertNRIFormatToVK   :: proc(format: Format) -> u32 ---
	GetFormatProps         :: proc(format: Format) -> ^FormatProps ---

	// Strings
	GetGraphicsAPIString :: proc(graphicsAPI: GraphicsAPI) -> cstring ---
}

