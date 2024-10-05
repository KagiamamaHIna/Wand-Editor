extern "C" {
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
}

#include "ImageLoad.h"

namespace image {
	stb_image::stb_image(const std::string& FilePath, int req_comp) {//req_comp为请求的颜色通道数
		imageData = stbi_load(FilePath.c_str(), &width, &height, &channels, req_comp);
	}

	stb_image::~stb_image() {
		stbi_image_free(imageData);
	}

	bool stb_image::WritePng(std::string& path) const {
		return static_cast<bool>(stbi_write_png(path.c_str(), width, height, channels, imageData, width * channels));
	}

	bool stb_image::WritePng(const char* path) const {
		return static_cast<bool>(stbi_write_png(path, width, height, channels, imageData, width * channels));
	}
}
