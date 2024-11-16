function GitHubProxy_Link(str,raw)
    local GitHubProxyLink = "https://ghp.ci/"
    if raw then
		return GitHubProxyLink .. "https://raw.githubusercontent.com" .. str
    else
		return GitHubProxyLink .. "https://github.com" .. str
	end
end
--上述是我目前找到的一个可用镜像（截止2024.7.3)

--这个函数是直接访问github原始页面的，不是镜像
function GitHub_Link(str, raw)
	if raw then
		return "https://raw.githubusercontent.com" .. str
    else
		return "https://github.com" .. str
	end
end
--可以视条件更改CurrentMirror指向的函数
CurrentMirror = GitHubProxy_Link
