// © 2025 NVIDIA Corporation

// Goal: providing easy-to-use access to modern upscalers: DLSS, FSR, XESS, NIS
package nri

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib"}
}


NRI_UPSCALER_H :: 1

NriUpscaler     :: struct {}
NriUpscalerType :: u8 // Name                                     // Notes

NriUpscalerType_ :: enum u32 {
	NIS     = 0, // Name                                     // Notes
	FSR     = 1, // Name                                     // Notes
	XESS    = 2, // Name                                     // Notes
	DLSR    = 3, // Name                                     // Notes
	DLRR    = 4, // Name                                     // Notes
	MAX_NUM = 5, // Name                                     // Notes
} // Name                                     // Notes

NriUpscalerMode_ :: enum u32 {
	NATIVE            = 0, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	ULTRA_QUALITY     = 1, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	QUALITY           = 2, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	BALANCED          = 3, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	PERFORMANCE       = 4, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	ULTRA_PERFORMANCE = 5, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	MAX_NUM           = 6, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
} // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)

NriUpscalerMode :: u8 // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
NriUpscalerBits :: u16

NriUpscalerBits_ :: enum u32 {
	NONE           = 0,
	HDR            = 1,
	SRGB           = 2,
	USE_EXPOSURE   = 4,
	USE_REACTIVE   = 8,
	DEPTH_INVERTED = 16,
	DEPTH_INFINITE = 32,
	DEPTH_LINEAR   = 64,
	MV_UPSCALED    = 128,
	MV_JITTERED    = 256,
}

NriDispatchUpscaleBits_ :: enum u32 {
	NONE                = 0,
	RESET_HISTORY       = 1,
	USE_SPECULAR_MOTION = 2,
}

NriDispatchUpscaleBits :: u8

NriUpscalerDesc :: struct {
	upscaleResolution: NriDim2_t,         // output resolution
	type:              NriUpscalerType,
	mode:              NriUpscalerMode,   // not needed for NIS
	flags:             NriUpscalerBits,
	preset:            u8,                // preset for DLSR or XESS (0 default, >1 presets A, B, C...)
	commandBuffer:     ^NriCommandBuffer, // a non-copy-only command buffer in opened state, submission must be done manually ("wait for idle" executed, if not provided)
}

NriUpscalerProps :: struct {
	scalingFactor:       f32,       // per dimension scaling factor
	mipBias:             f32,       // mip bias for materials textures, computed as "-log2(scalingFactor) - 1" (keep an eye on normal maps)
	upscaleResolution:   NriDim2_t, // output resolution
	renderResolution:    NriDim2_t, // optimal render resolution
	renderResolutionMin: NriDim2_t, // minimal render resolution (for Dynamic Resolution Scaling)
	jitterPhaseNum:      u8,        // minimal number of phases in the jitter sequence, computed as "ceil(8 * scalingFactor ^ 2)" ("Halton(2, 3)" recommended)
}

NriUpscalerResource :: struct {
	texture:    ^NriTexture,
	descriptor: ^NriDescriptor, // "SHADER_RESOURCE" or "SHADER_RESOURCE_STORAGE", see comments below
}

// Guide buffers
NriUpscalerGuides :: struct {
	mv:       NriUpscalerResource, // .xy - surface motion
	depth:    NriUpscalerResource, // .x - HW depth
	exposure: NriUpscalerResource, // .x - 1x1 exposure
	reactive: NriUpscalerResource, // .x - bias towards "input"
} // For FSR, XESS, DLSR

NriDenoiserGuides :: struct {
	mv:               NriUpscalerResource, // .xy - surface motion
	depth:            NriUpscalerResource, // .x - HW or linear depth
	normalRoughness:  NriUpscalerResource, // .xyz - world-space normal (not encoded), .w - linear roughness
	diffuseAlbedo:    NriUpscalerResource, // .xyz - diffuse albedo (LDR sky color for sky)
	specularAlbedo:   NriUpscalerResource, // .xyz - specular albedo (environment BRDF)
	specularMvOrHitT: NriUpscalerResource, // .xy - specular virtual motion of the reflected world, or .x - specular hit distance otherwise
	exposure:         NriUpscalerResource, // .x - 1x1 exposure
	reactive:         NriUpscalerResource, // .x - bias towards "input"
	sss:              NriUpscalerResource, // .x - subsurface scattering, computed as "Luminance(colorAfterSSS - colorBeforeSSS)"
} // For DLRR

// Settings
NriNISSettings :: struct {
	sharpness: f32, // [0; 1]
}

NriFSRSettings :: struct {
	zNear:                   f32, // distance to the near plane (units)
	zFar:                    f32, // distance to the far plane, unused if "DEPTH_INFINITE" is set (units)
	verticalFov:             f32, // vertical field of view angle (radians)
	frameTime:               f32, // the time elapsed since the last frame (ms)
	viewSpaceToMetersFactor: f32, // for converting view space units to meters (m/unit)
	sharpness:               f32, // [0; 1]
}

NriDLRRSettings :: struct {
	worldToViewMatrix: [16]f32, // {Xx, Yx, Zx, 0, Xy, Yy, Zy, 0, Xz, Yz, Zz, 0, Tx, Ty, Tz, 1}, where {X, Y, Z} - axises, T - translation
	viewToClipMatrix:  [16]f32, // {-, -, -, 0, -, -, -, 0, -, -, -, A, -, -, -, B}, where {A; B} = {0; 1} for ortho or {-1/+1; 0} for perspective projections
}

NriDispatchUpscaleDesc :: struct {
	// Output (required "SHADER_RESOURCE_STORAGE" for resource state & descriptor)
	output: NriUpscalerResource, // .xyz - upscaled RGB color

	// Input (required "SHADER_RESOURCE" for resource state & descriptor)
	input: NriUpscalerResource, // .xyz - input RGB color

	guides: struct #raw_union {
		upscaler: NriUpscalerGuides, //      FSR, XESS, DLSR
		denoiser: NriDenoiserGuides, //      DLRR (sRGB not supported)
	},

	settings: struct #raw_union {
		nis:  NriNISSettings,  //      NIS settings
		fsr:  NriFSRSettings,  //      FSR settings
		dlrr: NriDLRRSettings, //      DLRR settings
	},

	currentResolution: NriDim2_t,   // current render resolution for inputs and guides, renderResolutionMin <= currentResolution <= renderResolution
	cameraJitter:      NriFloat2_t, // pointing towards the pixel center, in [-0.5; 0.5] range
	mvScale:           NriFloat2_t, // used to convert motion vectors to pixel space
	flags:             NriDispatchUpscaleBits,
}

// Threadsafe: yes
NriUpscalerInterface :: struct {
	CreateUpscaler:      proc "c" (device: ^NriDevice, upscalerDesc: ^NriUpscalerDesc, upscaler: ^^NriUpscaler) -> NriResult,
	DestroyUpscaler:     proc "c" (upscaler: ^NriUpscaler),
	IsUpscalerSupported: proc "c" (device: ^NriDevice, type: NriUpscalerType) -> bool,
	GetUpscalerProps:    proc "c" (upscaler: ^NriUpscaler, upscalerProps: ^NriUpscalerProps),

	// Command buffer
	// {
	// Dispatch (changes descriptor pool, pipeline layout and pipeline, barriers are externally controlled)
	CmdDispatchUpscale: proc "c" (commandBuffer: ^NriCommandBuffer, upscaler: ^NriUpscaler, dispatchUpscaleDesc: ^NriDispatchUpscaleDesc),
}

