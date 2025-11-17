package graphics

import nri "./NRI/"
import "core:fmt"

main :: proc() {
	adapter_num: u32 = 0
	nri.nriEnumerateAdapters(nil, &adapter_num)

	fmt.print("dd")
	fmt.print("adapter num:", adapter_num)
}
