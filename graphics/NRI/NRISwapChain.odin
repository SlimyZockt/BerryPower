// © 2021 NVIDIA Corporation

// Goal: presentation functionality
package nri

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib"}
}


NRI_SWAP_CHAIN_H :: 1

// Color space:
//  - BT.709 - LDR https://en.wikipedia.org/wiki/Rec._709
//  - BT.2020 - HDR https://en.wikipedia.org/wiki/Rec._2020
// Transfer function:
//  - G10 - linear (gamma 1.0)
//  - G22 - sRGB (gamma ~2.2)
//  - G2084 - SMPTE ST.2084 (Perceptual Quantization)
// Bits per channel:
//  - 8, 10, 16 (float)
NriSwapChainFormat :: u8

// Color space:
//  - BT.709 - LDR https://en.wikipedia.org/wiki/Rec._709
//  - BT.2020 - HDR https://en.wikipedia.org/wiki/Rec._2020
// Transfer function:
//  - G10 - linear (gamma 1.0)
//  - G22 - sRGB (gamma ~2.2)
//  - G2084 - SMPTE ST.2084 (Perceptual Quantization)
// Bits per channel:
//  - 8, 10, 16 (float)
NriSwapChainFormat_ :: enum u32 {
	// Transfer function:
	//  - G10 - linear (gamma 1.0)
	//  - G22 - sRGB (gamma ~2.2)
	//  - G2084 - SMPTE ST.2084 (Perceptual Quantization)
	// Bits per channel:
	//  - 8, 10, 16 (float)
	BT709_G10_16BIT    = 0,

	// Transfer function:
	//  - G10 - linear (gamma 1.0)
	//  - G22 - sRGB (gamma ~2.2)
	//  - G2084 - SMPTE ST.2084 (Perceptual Quantization)
	// Bits per channel:
	//  - 8, 10, 16 (float)
	BT709_G22_8BIT     = 1,

	// Transfer function:
	//  - G10 - linear (gamma 1.0)
	//  - G22 - sRGB (gamma ~2.2)
	//  - G2084 - SMPTE ST.2084 (Perceptual Quantization)
	// Bits per channel:
	//  - 8, 10, 16 (float)
	BT709_G22_10BIT    = 2,

	// Transfer function:
	//  - G10 - linear (gamma 1.0)
	//  - G22 - sRGB (gamma ~2.2)
	//  - G2084 - SMPTE ST.2084 (Perceptual Quantization)
	// Bits per channel:
	//  - 8, 10, 16 (float)
	BT2020_G2084_10BIT = 3,

	// Transfer function:
	//  - G10 - linear (gamma 1.0)
	//  - G22 - sRGB (gamma ~2.2)
	//  - G2084 - SMPTE ST.2084 (Perceptual Quantization)
	// Bits per channel:
	//  - 8, 10, 16 (float)
	MAX_NUM            = 4,
}

// https://registry.khronos.org/vulkan/specs/latest/man/html/VkPresentScalingFlagBitsKHR.html
NriScaling_ :: enum u32 {
	ONE_TO_ONE = 0,
	STRETCH    = 1,
	MAX_NUM    = 2,
}

// https://registry.khronos.org/vulkan/specs/latest/man/html/VkPresentScalingFlagBitsKHR.html
NriScaling :: u8

// https://registry.khronos.org/vulkan/specs/latest/man/html/VkPresentGravityFlagBitsKHR.html
NriGravity_ :: enum u32 {
	MIN      = 0,
	MAX      = 1,
	CENTERED = 2,
	MAX_NUM  = 3,
}

// https://registry.khronos.org/vulkan/specs/latest/man/html/VkPresentGravityFlagBitsKHR.html
NriGravity :: u8

NriSwapChainBits_ :: enum u32 {
	NONE              = 0,
	VSYNC             = 1,
	WAITABLE          = 2,
	ALLOW_TEARING     = 4,
	ALLOW_LOW_LATENCY = 8,
}

NriSwapChainBits :: u8

NriWindowsWindow :: struct {
	hwnd: rawptr, //    HWND
} // Expects "WIN32" platform macro

NriX11Window :: struct {
	dpy:    rawptr, //    Display
	window: u64,    //    Window
} // Expects "NRI_ENABLE_XLIB_SUPPORT"

NriWaylandWindow :: struct {
	display: rawptr, //    wl_display
	surface: rawptr, //    wl_surface
} // Expects "NRI_ENABLE_WAYLAND_SUPPORT"

NriMetalWindow :: struct {
	caMetalLayer: rawptr, //    CAMetalLayer
} // Expects "APPLE" platform macro

NriWindow :: struct {
	// Only one entity must be initialized
	windows: NriWindowsWindow,
	x11:     NriX11Window,
	wayland: NriWaylandWindow,
	metal:   NriMetalWindow,
}

// SwapChain textures will be created as "color attachment" resources
// queuedFrameNum = 0 - auto-selection between 1 (for waitable) or 2 (otherwise)
// queuedFrameNum = 2 - recommended if the GPU frame time is less than the desired frame time, but the sum of 2 frames is greater
NriSwapChainDesc :: struct {
	window:         NriWindow,
	queue:          ^NriQueue,          // GRAPHICS or COMPUTE (requires "features.presentFromCompute")
	width:          NriDim_t,
	height:         NriDim_t,
	textureNum:     u8,                 // desired value, real value must be queried using "GetSwapChainTextures"
	format:         NriSwapChainFormat, // desired format, real value must be queried using "GetTextureDesc" for one of the swap chain textures
	flags:          NriSwapChainBits,
	queuedFrameNum: u8,                 // aka "max frame latency", aka "number of frames in flight" (mostly for D3D11)

	// Present scaling and positioning, silently ignored if "features.resizableSwapChain" is not supported
	scaling:  NriScaling, // VK: if scaling is not supported, "OUT_OF_DATE" error is triggered on resizing
	gravityX: NriGravity,
	gravityY: NriGravity,
}

NriChromaticityCoords :: struct {
	x, y: f32, // [0; 1]
}

// Describes color settings and capabilities of the closest display:
//  - Luminance provided in nits (cd/m2)
//  - SDR = standard dynamic range
//  - LDR = low dynamic range (in many cases LDR == SDR)
//  - HDR = high dynamic range, assumes G2084:
//      - BT709_G10_16BIT: HDR gets enabled and applied implicitly if Windows HDR is enabled
//      - BT2020_G2084_10BIT: HDR requires explicit color conversions and enabled HDR in Windows
//  - "SDR scale in HDR mode" = sdrLuminance / 80
NriDisplayDesc :: struct {
	redPrimary:            NriChromaticityCoords,
	greenPrimary:          NriChromaticityCoords,
	bluePrimary:           NriChromaticityCoords,
	whitePoint:            NriChromaticityCoords,
	minLuminance:          f32,
	maxLuminance:          f32,
	maxFullFrameLuminance: f32,
	sdrLuminance:          f32,
	isHDR:                 bool,
}

// Threadsafe: yes
NriSwapChainInterface :: struct {
	CreateSwapChain:      proc "c" (device: ^NriDevice, swapChainDesc: ^NriSwapChainDesc, swapChain: ^^NriSwapChain) -> NriResult,
	DestroySwapChain:     proc "c" (swapChain: ^NriSwapChain),
	GetSwapChainTextures: proc "c" (swapChain: ^NriSwapChain, textureNum: ^u32) -> ^^NriTexture,

	// Returns "FAILURE" if swap chain's window is outside of all monitors
	GetDisplayDesc: proc "c" (swapChain: ^NriSwapChain, displayDesc: ^NriDisplayDesc) -> NriResult,

	// VK only: may return "OUT_OF_DATE", fences must be created with "SWAPCHAIN_SEMAPHORE" initial value
	AcquireNextTexture: proc "c" (swapChain: ^NriSwapChain, acquireSemaphore: ^NriFence, textureIndex: ^u32) -> NriResult,
	WaitForPresent:     proc "c" (swapChain: ^NriSwapChain) -> NriResult, // call once right before input sampling (must be called starting from the 1st frame)
	QueuePresent:       proc "c" (swapChain: ^NriSwapChain, releaseSemaphore: ^NriFence) -> NriResult,
}

