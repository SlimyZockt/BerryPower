// © 2021 NVIDIA Corporation

// Goal: device creation
package nri

import "core:c"

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib"}
}


NRI_DEVICE_CREATION_H :: 1

NriMessage_ :: enum u32 {
	INFO    = 0,
	WARNING = 1,
	ERROR   = 2,
	MAX_NUM = 3,
}

NriMessage :: u8

// Callbacks must be thread safe
NriAllocationCallbacks :: struct {
	Allocate:                           proc "c" (userArg: rawptr, size: c.size_t, alignment: c.size_t) -> rawptr,
	Reallocate:                         proc "c" (userArg: rawptr, memory: rawptr, size: c.size_t, alignment: c.size_t) -> rawptr,
	Free:                               proc "c" (userArg: rawptr, memory: rawptr),
	userArg:                            rawptr,
	disable3rdPartyAllocationCallbacks: bool, // to use "AllocationCallbacks" only for NRI needs
}

NriCallbackInterface :: struct {
	MessageCallback: proc "c" (messageType: NriMessage, file: cstring, line: u32, message: cstring, userArg: rawptr),
	AbortExecution:  proc "c" (userArg: rawptr), // break on "Message::ERROR" if provided
	userArg:         rawptr,
}

// Use largest offset for the resource type planned to be used as an unbounded array
NriVKBindingOffsets :: struct {
	samplerOffset:                 u32,
	textureOffset:                 u32,
	constantBufferOffset:          u32,
	storageTextureAndBufferOffset: u32,
}

NriVKExtensions :: struct {
	instanceExtensions:   ^cstring,
	instanceExtensionNum: u32,
	deviceExtensions:     ^cstring,
	deviceExtensionNum:   u32,
}

// A collection of queues of the same type
NriQueueFamilyDesc :: struct {
	queuePriorities: ^f32, // [-1; 1]: low < 0, normal = 0, high > 0 ("queueNum" entries expected)
	queueNum:        u32,
	queueType:       NriQueueType,
}

NriDeviceCreationDesc :: struct {
	graphicsAPI:         NriGraphicsAPI,
	robustness:          NriRobustness,
	adapterDesc:         ^NriAdapterDesc,
	callbackInterface:   NriCallbackInterface,
	allocationCallbacks: NriAllocationCallbacks,

	// One "GRAPHICS" queue is created by default
	queueFamilies:  ^NriQueueFamilyDesc,
	queueFamilyNum: u32, // put "GRAPHICS" queue at the beginning of the list

	// D3D specific
	d3dShaderExtRegister: u32, // vendor specific shader extensions (default is "NRI_SHADER_EXT_REGISTER", space is always "0")
	d3dZeroBufferSize:    u32, // no "memset" functionality in D3D, "CmdZeroBuffer" implemented via a bunch of copies (4 Mb by default)

	// Vulkan specific
	vkBindingOffsets: NriVKBindingOffsets,
	vkExtensions:     NriVKExtensions, // to enable

	// Switches (disabled by default)
	enableNRIValidation:               bool, // embedded validation layer, checks for NRI specifics
	enableGraphicsAPIValidation:       bool, // GAPI-provided validation layer
	enableD3D11CommandBufferEmulation: bool, // enable? but why? (auto-enabled if deferred contexts are not supported)
	enableD3D12RayTracingValidation:   bool, // slow but useful, can only be enabled if envvar "NV_ALLOW_RAYTRACING_VALIDATION" is set to "1"
	enableMemoryZeroInitialization:    bool, // page-clears are fast, but memory is not cleared by default in VK

	// Switches (enabled by default)
	disableVKRayTracing:          bool, // to save CPU memory in some implementations
	disableD3D12EnhancedBarriers: bool, // even if AgilitySDK is in use, some apps still use legacy barriers. It can be important for integrations
}

@(default_calling_convention="c")
foreign lib {
	// if "adapterDescs == NULL", then "adapterDescNum" is set to the number of adapters
	// else "adapterDescNum" must be set to number of elements in "adapterDescs"
	nriEnumerateAdapters :: proc(adapterDescs: ^NriAdapterDesc, adapterDescNum: ^u32) -> NriResult ---
	nriCreateDevice      :: proc(deviceCreationDesc: ^NriDeviceCreationDesc, device: ^^NriDevice) -> NriResult ---
	nriDestroyDevice     :: proc(device: ^NriDevice) ---

	// It's global state for D3D, not needed for VK because validation is tied to the logical device
	nriReportLiveObjects :: proc() ---
}

