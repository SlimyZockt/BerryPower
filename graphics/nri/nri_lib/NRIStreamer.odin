// © 2024 NVIDIA Corporation

// Goal: data streaming
package nri_lib

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib", "system:stdc++"}
}


NRI_STREAMER_H :: 1

Streamer :: struct {}

DataSize :: struct {
	data: rawptr,
	size: u64,
}

BufferOffset :: struct {
	buffer: ^Buffer,
	offset: u64,
}

StreamerDesc :: struct {
	// Statically allocated ring-buffer for dynamic constants
	constantBufferMemoryLocation: MemoryLocation, // UPLOAD or DEVICE_UPLOAD
	constantBufferSize:           u64,            // should be large enough to avoid overwriting data for enqueued frames

	// Dynamically (re)allocated ring-buffer for copying and rendering
	dynamicBufferMemoryLocation: MemoryLocation, // UPLOAD or DEVICE_UPLOAD
	dynamicBufferDesc:           BufferDesc,     // "size" is ignored
	queuedFrameNum:              u32,            // number of frames "in-flight" (usually 1-3), adds 1 under the hood for the current "not-yet-committed" frame
}

StreamBufferDataDesc :: struct {
	// Data to upload
	dataChunks:         ^DataSize, // will be concatenated in dynamic buffer memory
	dataChunkNum:       u32,
	placementAlignment: u32,       // desired alignment for "BufferOffset::offset"

	// Destination
	dstBuffer: ^Buffer,
	dstOffset: u64,
}

StreamTextureDataDesc :: struct {
	// Data to upload
	data:           rawptr,
	dataRowPitch:   u32,
	dataSlicePitch: u32,

	// Destination
	dstTexture: ^Texture,
	dstRegion:  TextureRegionDesc,
}

// Threadsafe: yes
StreamerInterface :: struct {
	CreateStreamer:  proc "c" (device: ^Device, streamerDesc: ^StreamerDesc, streamer: ^^Streamer) -> Result,
	DestroyStreamer: proc "c" (streamer: ^Streamer),

	// Statically allocated (never changes)
	GetStreamerConstantBuffer: proc "c" (streamer: ^Streamer) -> ^Buffer,

	// (HOST) Stream data to a dynamic buffer. Return "buffer & offset" for direct usage in the current frame
	StreamBufferData:  proc "c" (streamer: ^Streamer, streamBufferDataDesc: ^StreamBufferDataDesc) -> BufferOffset,
	StreamTextureData: proc "c" (streamer: ^Streamer, streamTextureDataDesc: ^StreamTextureDataDesc) -> BufferOffset,

	// (HOST) Stream data to a constant buffer. Return "offset" in "GetStreamerConstantBuffer" for direct usage in the current frame
	StreamConstantData: proc "c" (streamer: ^Streamer, data: rawptr, dataSize: u32) -> u32,

	// Command buffer
	// {
	// (DEVICE) Copy data to destinations (if any), which must be in "COPY_DESTINATION" state
	CmdCopyStreamedData: proc "c" (commandBuffer: ^CommandBuffer, streamer: ^Streamer),

	// }
	
	// (HOST) Must be called once at the very end of the frame
	EndStreamerFrame: proc "c" (streamer: ^Streamer),
}

