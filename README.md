# tools

subdomain_enum.sh
使用amass、subfinder、findomain、assetfinder收集子域名，再使用naabu对收集到的子域名进行全端口探测，之后用httpx判断存活，将状态码为200，403的进行保存，最后通过aquatone进行屏幕截图
