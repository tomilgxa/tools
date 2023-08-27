#!/bin/bash

# 判断参数是否正确
if [ $# -lt 2 ]; then
    echo "请提供正确的参数"
    echo "用法: $0 [-f <目标文件>] [-d <目标>] [-o <输出文件名>]"
    exit 1
fi

# 处理参数
while getopts ":f:d:o:" opt; do
    case $opt in
        f)
            # 读取目标文件
            target_list_file=$OPTARG
            if [ ! -f "$target_list_file" ]; then
                echo "目标文件不存在"
                exit 1
            fi
            ;;
        d)
            # 直接指定目标
            target=$OPTARG
            ;;
        o)
            # 指定输出文件名
            output_file_name=$OPTARG
            ;;
        \?)
            echo "无效选项: -$OPTARG"
            exit 1
            ;;
        :)
            echo "选项 -$OPTARG 需要参数."
            exit 1
            ;;
    esac
done

# 输出目录
output_dir="subdomain_enum_results"

# 创建目录
mkdir -p "$output_dir"

# 活动子域名文件
alive_subdomains_file="${output_dir}/${output_file_name}_alive_subdomains.txt"

# 清空文件
> "$alive_subdomains_file"

# 临时文件保存合并结果
temp_file=$(mktemp)

# 枚举子域名
function enumerate_subdomains {
    local target=$1

    echo "开始枚举"
    # 使用 amass 收集到临时文件
    amass enum --passive -d "$target" >> "$temp_file"

    # 使用 subfinder 收集到临时文件
    subfinder -d "$target" -t 30 >> "$temp_file"

    # 使用 findomain 收集到临时文件
    findomain -t "$target" -q --threads 30 >> "$temp_file"

    # 使用 assetfinder 收集到临时文件
    assetfinder --subs-only "$target" >> "$temp_file"
}

if [ -n "$target_list_file" ]; then
    # 从文件中读取目标并枚举
    while IFS= read -r target; do
        # 空目标跳过
        if [ -z "$target" ]; then
            echo "无效目标"
            continue
        fi

        enumerate_subdomains "$target"
    done < "$target_list_file"
fi

if [ -n "$target" ]; then
    # 直接指定目标并枚举
    enumerate_subdomains "$target"
fi

# 对临时文件进行去重和清理
sort -u "$temp_file" -o "$temp_file"
sed -i '/^$/d' "$temp_file"



# 使用 httpx 进行活动子域名筛选，并追加到结果文件
naabu -silent -top-ports full -rate 3000 -c 50 -l "$temp_file" -o "$temp_file"
httpx -l "$temp_file" -t 1000 -mc 200,403 -o "$alive_subdomains_file"

# 输出文件
output_subdomains_file="${output_dir}/${output_file_name}_subdomains.txt"

# 清空文件
> "$output_subdomains_file"

# 将临时文件追加到输出文件
cat "$temp_file" >> "$output_subdomains_file"

echo "活动子域名保存在 $alive_subdomains_file"
echo "所有子域名保存在 $output_subdomains_file"

# aquatone截屏
cat $alive_subdomains_file | aquatone -out "/root/tool/aquatone/${output_file_name}"
 
# 删除临时文件
rm "$temp_file"
