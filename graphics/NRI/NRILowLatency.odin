// © 2024 NVIDIA Corporation

// Goal: minimizing latency between input sampling and frame presentation
package nri

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib"}
}


NRI_LOW_LATENCY_H :: 1

// us = microseconds
NriLatencyMarker :: u8 // Should be called:

// us = microseconds
NriLatencyMarker_ :: enum u32 {
	// us = microseconds
	SIMULATION_START    = 0, // Should be called:

	// us = microseconds
	SIMULATION_END      = 1, // Should be called:

	// us = microseconds
	RENDER_SUBMIT_START = 2, // Should be called:

	// us = microseconds
	RENDER_SUBMIT_END   = 3, // Should be called:

	// us = microseconds
	INPUT_SAMPLE        = 6, // Should be called:

	// us = microseconds
	MAX_NUM             = 7, // Should be called:
} // Should be called:

NriLatencySleepMode :: struct {
	minIntervalUs:   u32,  // minimum allowed frame interval (0 - no frame rate limit)
	lowLatencyMode:  bool, // low latency mode enablement
	lowLatencyBoost: bool, // hint to increase performance to provide additional latency savings at a cost of increased power consumption
}

NriLatencyReport :: struct {
	inputSampleTimeUs:        u64, // when "INPUT_SAMPLE" marker is set
	simulationStartTimeUs:    u64, // when "SIMULATION_START" marker is set
	simulationEndTimeUs:      u64, // when "SIMULATION_END" marker is set
	renderSubmitStartTimeUs:  u64, // when "RENDER_SUBMIT_START" marker is set
	renderSubmitEndTimeUs:    u64, // when "RENDER_SUBMIT_END" marker is set
	presentStartTimeUs:       u64, // right before "Present"
	presentEndTimeUs:         u64, // right after "Present"
	driverStartTimeUs:        u64, // when the first "QueueSubmitTrackable" is called
	driverEndTimeUs:          u64, // when the final "QueueSubmitTrackable" hands off from the driver
	osRenderQueueStartTimeUs: u64,
	osRenderQueueEndTimeUs:   u64,
	gpuRenderStartTimeUs:     u64, // when the first submission reaches the GPU
	gpuRenderEndTimeUs:       u64, // when the final submission finishes on the GPU
} // The time stamp written:

// Multi-swapchain is supported only by VK
// "QueueSubmitDesc::swapChain" must be used to associate work submission with a low latency swap chain
// Threadsafe: no
NriLowLatencyInterface :: struct {
	SetLatencySleepMode: proc "c" (swapChain: ^NriSwapChain, latencySleepMode: ^NriLatencySleepMode) -> NriResult,
	SetLatencyMarker:    proc "c" (swapChain: ^NriSwapChain, latencyMarker: NriLatencyMarker) -> NriResult,
	LatencySleep:        proc "c" (swapChain: ^NriSwapChain) -> NriResult, // call once before "INPUT_SAMPLE"
	GetLatencyReport:    proc "c" (swapChain: ^NriSwapChain, latencyReport: ^NriLatencyReport) -> NriResult,
}

