#ifndef IMAGELOAD_H_
#define IMAGELOAD_H_

#include <string>
extern "C" {
	void stbi_set_flip_vertically_on_load(int flag_true_if_should_flip);
}

namespace image {
	struct rgba {
		union {
			struct {
				unsigned char r;
				unsigned char g;
				unsigned char b;
				unsigned char a;
			};
			unsigned char rgbaArray[4] = { 0,0,0,0 };
		};
		bool Eq(unsigned char _r, unsigned char _g, unsigned char _b = 0, unsigned char _a = 255) const {
			switch (channels) {
			case 1: {
				if (r != _r) {
					return false;
				}
				return true;
			}
			case 3: {
				if (r != _r) {
					return false;
				}
				if (g != _g) {
					return false;
				}
				if (b != _b) {
					return false;
				}
				return true;
			}
			case 4: {
				if (r != _r) {
					return false;
				}
				if (g != _g) {
					return false;
				}
				if (b != _b) {
					return false;
				}
				if (a != _a) {
					return false;
				}
				return true;
			}
			}
			return false;
		}
		bool Eq(unsigned long color) const {
			return color == GetHex();
		}
		unsigned long GetHex() const {//转十六进制
			long result = 0;
			for (int i = 0; i < channels - 1; i++) {
				result |= rgbaArray[i];
				result <<= 8;
			}
			result |= rgbaArray[channels - 1];
			return result;
		}
		int channels = 0;//可以用于确认是哪种通道的
	};

	class stb_image {
	public:
		stb_image(const std::string& FilePath, int req_comp = 0);//req_comp为请求的颜色通道数

		stb_image(const char* FilePath, int req_comp = 0) : stb_image(std::string(FilePath), req_comp) {
		}
		/*
		如果 req_comp 设置为 0，stbi_load 将加载图像的所有颜色通道（例如，RGB 或 RGBA）。
		如果 req_comp 设置为 1，stbi_load 将加载图像的灰度通道（单通道）。
		如果 req_comp 设置为 3，stbi_load 将加载图像的 RGB 通道。
		如果 req_comp 设置为 4，stbi_load 将加载图像的 RGBA 通道。
		*/

		rgba GetPixel(int x, int y) {//获取像素
			int pixelIndex = (y * width + x) * channels;//计算像素索引
			rgba result;
			result.channels = channels;//设置通道数
			for (int i = 0; i < channels; i++) {//设置像素的rgba颜色
				result.rgbaArray[i] = imageData[pixelIndex + i];
			}
			return result;
		}

		unsigned char* GetImageData() const {
			return imageData;
		}
		int GetWidth() const {
			return width;
		}
		int GetHeight() const {
			return height;
		}
		int GetChannels() const {
			return channels;
		}

		bool WritePng(std::string& path) const;
		bool WritePng(const char* path) const;

		virtual ~stb_image();
	private:
		unsigned char* imageData = nullptr;
		int width = 0;//宽
		int height = 0;//高
		int channels = 0;//通道
	};

}

#endif
