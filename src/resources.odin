package main

import "core:flags/example"
import "core:fmt"
import "core:log"
import "core:math"
import "core:path/filepath"

import "core:strings"
import "vendor:cgltf"

import "loader"
import "renderer"

Array :: struct($T: typeid) {
	data:  []T,
	count: u32,
}

Resources :: struct {
	meshes: Array(renderer.Mesh),
	images: Array(renderer.Image),
}

load_image :: proc(res: ^Resources, new_img: ^renderer.Image, path: cstring) {

}


load_gltf :: proc(res: ^Resources, new_mesh: ^renderer.Mesh, path: cstring) -> bool {
	opt: cgltf.options
	data: ^cgltf.data
	result: cgltf.result

	vert_count: u64
	ind_count: u64
	prim_count: u64
	tex_offset: u32 = res.images.count

	data, result = cgltf.parse_file(opt, path)

	odin_str := string(path)
	dir, file := filepath.split(odin_str)
	new_mesh.name = strings.clone(file)


	fmt.println(new_mesh.name)
	if result != .success {
		log.errorf("CGLTF::Failed to Parse File: %s", path)
		return false
	}

	if cgltf.validate(data) != .success {
		log.errorf("CGLTF::Failed to Validate Data: %s", path)
		return false
	}

	result = cgltf.load_buffers(opt, data, path)

	for img in data.images {
		img_path, err := filepath.join({dir, string(img.uri)})
		cpath := strings.clone_to_cstring(img_path)

		new_img := get_new_image(res)
		load_image(res, new_img, cpath)

		fmt.println(cpath)
		delete(cpath)
	}

	return true
}


get_new_image :: proc(res: ^Resources) -> ^renderer.Image {
	img := &res.images.data[res.images.count]
	res.images.count += 1
	return img
}

get_new_mesh :: proc(res: ^Resources) -> ^renderer.Mesh {
	mesh := &res.meshes.data[res.meshes.count]
	res.meshes.count += 1
	return mesh
}

resources_init :: proc(res: ^Resources) {
	res.meshes.data = make([]renderer.Mesh, 100)
	res.images.data = make([]renderer.Image, 500)
}

load_model :: proc(res: ^Resources, path: cstring) {
	mesh := get_new_mesh(res)
	load_gltf(res, mesh, path)
}
