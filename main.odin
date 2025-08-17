package main
// import "vendor:wgpu"
import "core:log"

import "base:runtime" // or whatever version you want
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"
import lua "vendor:lua/5.4"

state: ^lua.State

lua_allocator :: proc "c" (ud: rawptr, ptr: rawptr, osize, nsize: c.size_t) -> (buf: rawptr) {
	old_size := int(osize)
	new_size := int(nsize)
	context = (^runtime.Context)(ud)^

	if ptr == nil {
		data, err := runtime.mem_alloc(new_size)
		return raw_data(data) if err == .None else nil
	} else {
		if nsize > 0 {
			data, err := runtime.mem_resize(ptr, old_size, new_size)
			return raw_data(data) if err == .None else nil
		} else {
			runtime.mem_free(ptr)
			return
		}
	}
}

ctx: runtime.Context

main :: proc() {
	_context := context
	context.logger = log.create_console_logger()
	state = lua.newstate(lua_allocator, &_context)
	defer lua.close(state)

	args := os.args
	if len(args) < 2 {
		log.panic("Argument missing")
	}

	if !os.is_file(args[1]) {
		log.panic("File not found")
	}

	lua_file, err := os.read_entire_file_from_filename_or_err(args[1])


	ensure(err == nil)


	lua.pushcfunction(state, proc "c" (L: ^lua.State) -> c.int {
		n := lua.gettop(state)
		context = ctx
		fmt.println("Hello from odin, Argument count:", n)

		return 0
	})
	lua.setglobal(state, "hello")
	lua.L_dostring(state, strings.clone_to_cstring(transmute(string)lua_file))
	str := lua.tostring(state, -1)
	fmt.println(str)
}
