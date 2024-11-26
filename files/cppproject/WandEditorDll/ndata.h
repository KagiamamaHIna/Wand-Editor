#pragma once
#include <filesystem>
#include <unordered_map>
#include <iostream>
#include <vector>
#include <fstream>
#include <exception>

namespace ndata {
	class DataWak;
	std::string VecU8ToStr(const std::vector<uint8_t>&);//将给定的数据转换成std::string
	std::vector<uint8_t> StrToVecU8(const std::string& str);//将给定的数据转换成std::vector<uint8_t> 
	DataWak wizard_get_pak(const std::string& path);//指定一个路径，将路径下的文件全部打包成DataWak的形式并返回
	void wizard_pak(const std::string& WakPath, const std::string& path);//指定一个路径，将路径下的文件全部打包成wak，带有data前缀
	void wizard_unpak(const std::string& WakPath, const std::string& path);//指定一个wak路径，将wak解包至指定路径下

	class DataWak {
	public:
		DataWak() {}//不含任何数据的data
		DataWak(const std::vector<uint8_t>& dataWak);//二进制文件数据构造
		DataWak(const std::string& WakPath) : DataWak(ReadBinFile(WakPath)) {}//从路径构造
		DataWak(const char* WakPath) : DataWak(std::string(WakPath)) {}//从路径构造
		virtual ~DataWak() = default;

		std::vector<uint8_t> DumpWak() const;//将数据导出成Wak的形式
		void DumpWakToFile(const std::string& path) const;//将数据导出到Wak文件里面
		void DumpFiles(const std::string& path) const;//将数据以文件的形式导出到文件夹里面
		std::vector<std::string> GetFileList() const;//获取所有文件路径

		void AddFile(const std::string& key, const std::vector<uint8_t>& file) {//增加文件
			std::string NewKey = "data/" + key;
			data[NewKey] = file;
		}

		bool RemoveFile(const std::string& key) {//移除文件
			if (HasFile(key)) {
				data.erase(key);
				return true;
			}
			return false;
		}

		bool HasFile(const std::string& key) const {//存在文件判断
			return static_cast<bool>(data.count(key));
		}

		const std::vector<uint8_t>& operator[](const std::string& key) const {
			return data.at(key);
		}

		std::vector<uint8_t>& operator[](const std::string& key) {
			return data.at(key);
		}

		std::unordered_map<std::string, std::vector<uint8_t>>& umap() {//访问原始哈希表
			return data;
		}
	protected:
		static std::vector<uint8_t> ReadBinFile(const std::string& path);//读取二进制文件
	private:
		std::unordered_map<std::string, std::vector<uint8_t>> data{};
	};

	class DataExceptionBase : public std::exception {
	public:
		DataExceptionBase(uint64_t ErrorPos) :ErrorPos(ErrorPos) {};
		virtual ~DataExceptionBase() = default;
		virtual const char* what() const = 0;
		uint64_t ErrorPos;
	};

	class DataNoOpenException : public DataExceptionBase {
	public:
		DataNoOpenException(uint64_t ErrorPos) : DataExceptionBase(ErrorPos) {};
		virtual const char* what() const {
			return "File not successfully opened";
		}
	};

	class DataFileOutOfBoundsException : public DataExceptionBase {
	public:
		DataFileOutOfBoundsException(uint64_t ErrorPos) : DataExceptionBase(ErrorPos) {};
		virtual const char* what() const {
			return "The value pointed to by the file pointer is out of bounds";
		}
	};

	class DataPathSizeOutOfBoundsException : public DataExceptionBase {
	public:
		DataPathSizeOutOfBoundsException(uint64_t ErrorPos) : DataExceptionBase(ErrorPos) {};
		virtual const char* what() const {
			return "Path data block too large";
		}
	};

	class DataFileTypeErrorException : public DataExceptionBase {
	public:
		DataFileTypeErrorException(uint64_t ErrorPos) : DataExceptionBase(ErrorPos) {};
		virtual const char* what() const {
			return "Not the correct data.wak file";
		}
	};
}
