// © 2025 NVIDIA Corporation

// Goal: ImGui rendering
package nri

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib"}
}


NRI_IMGUI_H :: 1

ImDrawList    :: struct {}
ImTextureData :: struct {}
NriImgui      :: struct {}
NriStreamer   :: struct {}

NriImguiDesc :: struct {
	descriptorPoolSize: u32, // upper bound of textures used by Imgui for drawing: {number of queued frames} * {number of "CmdDrawImgui" calls} * (1 + {"drawList->AddImage*" calls})
}

NriCopyImguiDataDesc :: struct {
	drawLists:   ^^ImDrawList,    // ImDrawData::CmdLists.Data
	drawListNum: u32,             // ImDrawData::CmdLists.Size
	textures:    ^^ImTextureData, // ImDrawData::Textures->Data (same as "ImGui::GetPlatformIO().Textures.Data")
	textureNum:  u32,             // ImDrawData::Textures->Size (same as "ImGui::GetPlatformIO().Textures.Size")
}

NriDrawImguiDesc :: struct {
	drawLists:        ^^ImDrawList, // ImDrawData::CmdLists.Data (same as for "CopyImguiDataDesc")
	drawListNum:      u32,          // ImDrawData::CmdLists.Size (same as for "CopyImguiDataDesc")
	displaySize:      NriDim2_t,    // ImDrawData::DisplaySize
	hdrScale:         f32,          // SDR intensity in HDR mode (1 by default)
	attachmentFormat: NriFormat,    // destination attachment (render target) format
	linearColor:      bool,         // apply de-gamma to vertex colors (needed for sRGB attachments and HDR)
}

// Threadsafe: yes
NriImguiInterface :: struct {
	CreateImgui:  proc "c" (device: ^NriDevice, imguiDesc: ^NriImguiDesc, imgui: ^^NriImgui) -> NriResult,
	DestroyImgui: proc "c" (imgui: ^NriImgui),

	// Command buffer
	// {
	// Copy
	CmdCopyImguiData: proc "c" (commandBuffer: ^NriCommandBuffer, streamer: ^NriStreamer, imgui: ^NriImgui, streamImguiDesc: ^NriCopyImguiDataDesc),

	// Draw (changes descriptor pool, pipeline layout and pipeline, barriers are externally controlled)
	CmdDrawImgui: proc "c" (commandBuffer: ^NriCommandBuffer, imgui: ^NriImgui, drawImguiDesc: ^NriDrawImguiDesc),
}

