local function GitHubProxy(str)
	local GitHubProxyLink = "https://mirror.ghproxy.com/"
    return GitHubProxyLink .. "https://raw.githubusercontent.com" .. str
end
--上述是我目前找到的一个可用镜像（截止2024.7.3)
--下面的函数是直接访问github原始页面的，不是镜像
local function GitHub(str)
    return "https://raw.githubusercontent.com" .. str
end
--可以视条件更改CurrentMirror指向的函数
CurrentMirror = GitHubProxy
