#include "LuaZip.h"

static bool unzip_to_directory(const char* zip_filename, const char* output_directory) {
	mz_zip_archive zip_archive;
	memset(&zip_archive, 0, sizeof(zip_archive));

	//打开 ZIP 文件
	if (!mz_zip_reader_init_file(&zip_archive, zip_filename, 0)) {
		return false;
	}

	//获取 ZIP 文件中的文件数量
	mz_uint file_count = mz_zip_reader_get_num_files(&zip_archive);

	//遍历 ZIP 文件中的每个条目
	for (mz_uint i = 0; i < file_count; i++) {
		mz_zip_archive_file_stat file_stat;
		if (!mz_zip_reader_file_stat(&zip_archive, i, &file_stat)) {
			mz_zip_reader_end(&zip_archive);
			return false;
		}

		//创建输出文件路径
		char output_path[sizeof(file_stat.m_filename)];
		snprintf(output_path, sizeof(output_path), "%s/%s", output_directory, file_stat.m_filename);

		//检查是否为目录
		if (mz_zip_reader_is_file_a_directory(&zip_archive, i)) {
			//创建目录
			std::filesystem::create_directories(output_path);
		}
		else {
			//解压文件到指定路径
			if (!mz_zip_reader_extract_to_file(&zip_archive, i, output_path, 0)) {
				mz_zip_reader_end(&zip_archive);
				return false;
			}
		}
	}
	//关闭 ZIP 文件
	mz_zip_reader_end(&zip_archive);
	return true;
}

namespace lua {
	int lua_Uncompress(lua_State* L) {
		const char* zip = luaL_checkstring(L, 1);
		const char* outputPath = luaL_checkstring(L, 2);
		lua_pushboolean(L, unzip_to_directory(zip, outputPath));
		return 1;
	}
}
