#include "ndata.h"

namespace ndata {
	static void FormatPath(std::string& str) {
		for (auto& v : str) {
			if (v == '\\') {
				v = '/';
			}
		}
	}

	std::string VecU8ToStr(const std::vector<uint8_t>& data) {
		return std::string(data.begin(), data.end());
	}

	std::vector<uint8_t> StrToVecU8(const std::string& str) {
		return std::vector<uint8_t>(str.begin(), str.end());
	}

	static std::vector<uint8_t> PAK__ReadBinFile(const std::string& path, bool& flag) {//读取二进制文件
		std::ifstream inputFile(path, std::ios::binary | std::ios::out);
		if (!inputFile.is_open()) {//未成功打开 
			flag = false;
			return std::vector<uint8_t>();
		}
		else {
			flag = true;
		}
		inputFile.seekg(0, std::ios::end);//移动文件指针以获得文件大小
		std::streamsize fileSize = inputFile.tellg();
		inputFile.seekg(0, std::ios::beg);

		std::vector<uint8_t> result(fileSize);
		inputFile.read((char*)result.data(), fileSize);
		return result;
	}

	DataWak wizard_get_pak(const std::string& path) {
		std::filesystem::recursive_directory_iterator DirIter(path);//用于获取文件
		size_t pathSize = path.size();
		DataWak data;
		for (const auto& entry : DirIter) {//加载文件
			if (entry.is_directory()) {
				continue;
			}
			std::string file = entry.path().string();
			FormatPath(file);
			bool flag;
			std::vector<uint8_t> fileData = PAK__ReadBinFile(file, flag);
			if (flag) {
				data.AddFile(file.substr(pathSize + 1), fileData);
			}
		}
		return data;
	}

	void wizard_pak(const std::string& WakPath, const std::string& path) {
		wizard_get_pak(path).DumpWakToFile(WakPath);
	}

	void wizard_unpak(const std::string& WakPath, const std::string& path) {
		DataWak(WakPath).DumpFiles(path);
	}

	//都是小端序 这里都是工具函数
	void WriteBinFile(const std::string& path, const std::vector<uint8_t>& BinData) {//写入二进制文件
		std::ofstream outputFile(path, std::ios::binary | std::ios::trunc);
		outputFile.write((const char*)BinData.data(), BinData.size());
		outputFile.close();
	}

	static void WriteUnpakFile(std::vector<uint8_t> data, const std::string& path) {
		size_t pos = path.rfind('/');
		std::string CreDir = path.substr(0, pos);
		std::filesystem::create_directories(CreDir);
		WriteBinFile(path.c_str(), data);
	}

	std::vector<uint8_t> DeepCopyU8(const std::vector<uint8_t>& srcData, size_t index, size_t size) {
		return std::vector<uint8_t>(srcData.begin() + index, srcData.begin() + index + size);
	}

	std::string DeepCopyU8ToStr(const std::vector<uint8_t>& srcData, size_t index, size_t size) {
		return std::string(srcData.begin() + index, srcData.begin() + index + size);
	}

	uint32_t GetU8VecDW(const std::vector<uint8_t>& srcData, size_t index) {
		uint32_t result = 0;
		result |= srcData[index + 3];
		result <<= 8;
		result |= srcData[index + 2];
		result <<= 8;
		result |= srcData[index + 1];
		result <<= 8;
		result |= srcData[index];
		return result;
	}

	static void PushDWUint8(std::vector<uint8_t>& data, uint32_t number) {
		for (uint32_t i = 0; i < 4; i++) {
			uint8_t bitmask = 0xFF;
			bitmask &= number;
			number >>= 8;
			data.push_back(bitmask);
		}
	}

	static void RWVecDWUint8(std::vector<uint8_t>& data, uint32_t number, size_t pos) {
		for (size_t i = 0; i < 4; i++) {
			uint8_t bitmask = 0xFF;
			bitmask &= number >> i * 8;
			data[pos] = bitmask;
			pos++;
		}
	}

	//往下为成员函数
	std::vector<uint8_t> DataWak::ReadBinFile(const std::string& path) {//读取二进制文件
		std::ifstream inputFile(path, std::ios::binary | std::ios::out);
		if (!inputFile.is_open()) {//未成功打开 
			throw DataNoOpenException(0);
		}
		inputFile.seekg(0, std::ios::end);//移动文件指针以获得文件大小
		std::streamsize fileSize = inputFile.tellg();
		inputFile.seekg(0, std::ios::beg);

		std::vector<uint8_t> result(fileSize);
		inputFile.read((char*)result.data(), fileSize);
		return result;
	}

	DataWak::DataWak(const std::vector<uint8_t>& dataWak) {
		size_t dataSize = dataWak.size();
		if (dataSize < 16) {
			throw DataFileTypeErrorException(0);
		}
		else if (dataSize == 16) {
			return;
		}
		uint32_t Files = GetU8VecDW(dataWak, 4);//文件数，但是没什么用
		uint32_t PathSize = GetU8VecDW(dataWak, 8);

		if (PathSize > dataSize) throw DataPathSizeOutOfBoundsException(16);

		for (size_t i = 16; i + 12 < PathSize; i += 12) {//第一个四字节是位置关系，第二个四字节是大小关系，第三个四字节是文件目录字符串的长度
			uint32_t FilePos = GetU8VecDW(dataWak, i);
			uint32_t FileSize = GetU8VecDW(dataWak, i + 4);
			uint32_t FilePathSize = GetU8VecDW(dataWak, i + 8);
			std::string path = DeepCopyU8ToStr(dataWak, i + 12, FilePathSize);
			if (FilePos > dataSize) {
				throw DataFileOutOfBoundsException(FilePos);
			}
			data[path] = DeepCopyU8(dataWak, FilePos, FileSize);//数据写入
			i += FilePathSize;
		}
		//构造完成
	}

	std::vector<uint8_t> DataWak::DumpWak() const {
		std::vector<uint8_t> result(16, 0);
		std::vector<uint8_t> PathData;
		std::vector<uint8_t> FileData;
		uint32_t files = data.size();//获取文件数量大小
		if (files == 0) {
			return result;
		}
		RWVecDWUint8(result, files, 4);
		for (const auto& v : data) {//先构造这两个，但是PathData还需要进行一步处理
			FileData.insert(FileData.end(), v.second.begin(), v.second.end());//插入文件数据
			FileData.push_back(0);//data的文件数据之间用一个0来分隔
			PushDWUint8(PathData, 0);//先填充0，后续构造完成后再写入正确的文件指针数据
			PushDWUint8(PathData, v.second.size());//填充文件大小
			PushDWUint8(PathData, v.first.size());//路径文本大小
			PathData.insert(PathData.end(), v.first.begin(), v.first.end());//插入路径数据
		}
		//因为现在PathData是不变动大小的了，所以可以写入路径块大小了
		RWVecDWUint8(result, PathData.size() + 16, 8);
		//现在已经构造完成了FileData，那么现在可以计算文件指针了
		uint32_t FilePos = PathData.size() + 16;
		for (size_t i = 0; i + 12 < PathData.size(); i += 12) {
			uint32_t FileSize = GetU8VecDW(PathData, i + 4);
			uint32_t FilePathSize = GetU8VecDW(PathData, i + 8);
			RWVecDWUint8(PathData, FilePos, i);//写入正确的文件指针
			i += FilePathSize;
			FilePos += FileSize + 1;//因为有个分隔用的0，所以这里要多偏移一位
		}
		//合并操作
		result.insert(result.end(), PathData.begin(), PathData.end());
		result.insert(result.end(), FileData.begin(), FileData.end());
		return result;
	}

	void DataWak::DumpWakToFile(const std::string& path) const {
		WriteBinFile(path, DumpWak());
	}

	void DataWak::DumpFiles(const std::string& path) const {
		std::string NewPath = path;
		char lastChar = NewPath[NewPath.size() - 1];
		if (lastChar != '/' && lastChar != '\\') {
			NewPath.push_back('/');
		}
		for (const auto& v : data) {
			WriteUnpakFile(v.second, NewPath + v.first);
		}
	}

	std::vector<std::string> DataWak::GetFileList() const {
		std::vector<std::string> result;
		for (const auto& v : data) {
			result.push_back(v.first);
		}
		return result;
	}
}
