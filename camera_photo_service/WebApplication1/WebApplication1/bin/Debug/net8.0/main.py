import sys
import json

def some_function():
    # 这里放置业务逻辑
    status_code = 1  # 1表示成功，2表示失败
    result_str = "操作成功完成"  # 返回的字符串信息
    
    return status_code, result_str

if __name__ == "__main__":
    # 当脚本直接运行时执行
    status_code, result_str = some_function()
    
    # 创建包含状态码和结果字符串的字典
    result = {
        "status_code": status_code,
        "message": result_str
    }
    
    # 将结果转换为JSON字符串并打印
    # C#将捕获这个JSON字符串并解析它
    print(json.dumps(result, ensure_ascii=False))
    
    # 同时设置退出码
    sys.exit(status_code)