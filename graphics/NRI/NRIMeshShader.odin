// © 2021 NVIDIA Corporation

// Goal: mesh shaders
// https://www.khronos.org/blog/mesh-shading-for-vulkan
// https://microsoft.github.io/DirectX-Specs/d3d/MeshShader.html
package nri

when ODIN_OS == .Linux {
	foreign import lib {"libNRI.a", "libNRI_VK.a", "libNRI_Shared.a", "libNRI_Validation.a", "libNRI_NONE.a", "system:stdc++"}
} else when ODIN_OS == .Windows {
	foreign import lib {"libNRI.lib", "libNRI_VK.lib", "libNRI_Shared.lib", "libNRI_Validation.lib", "libNRI_NONE.lib"}
}


NRI_MESH_SHADER_H :: 1

NriDrawMeshTasksDesc :: struct {
	x, y, z: u32,
}

// Threadsafe: no
NriMeshShaderInterface :: struct {
	// Command buffer
	// {
	// Draw
	CmdDrawMeshTasks:         proc "c" (commandBuffer: ^NriCommandBuffer, drawMeshTasksDesc: ^NriDrawMeshTasksDesc),
	CmdDrawMeshTasksIndirect: proc "c" (commandBuffer: ^NriCommandBuffer, buffer: ^NriBuffer, offset: u64, drawNum: u32, stride: u32, countBuffer: ^NriBuffer, countBufferOffset: u64), // buffer contains "DrawMeshTasksDesc" commands
}

