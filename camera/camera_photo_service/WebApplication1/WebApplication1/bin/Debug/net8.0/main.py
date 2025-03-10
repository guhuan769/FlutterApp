import sys
import json

def some_function(param1, param2):
    """
    执行某些操作并返回状态码和结果字符串
    param1: 第一个参数
    param2: 第二个参数
    """
    try:
        # 这里放置业务逻辑，使用传入的参数
        print(f"接收到参数: param1={param1}, param2={param2}", file=sys.stderr)
        
        # 示例逻辑：如果param1等于"success"则返回成功，否则返回失败
        if param1 == "success":
            status_code = 1
            result_str = f"操作成功完成，参数值: {param1}, {param2}"
        else:
            status_code = 2
            result_str = f"操作失败，参数值: {param1}, {param2}"
        
        return status_code, result_str
    except Exception as e:
        # 异常处理
        return 2, f"发生错误: {str(e)}"

if __name__ == "__main__":
    # 获取命令行参数
    # sys.argv[0]是脚本名称，sys.argv[1]开始是传入的参数
    
    # 设置默认参数值
    param1 = "default1"
    param2 = "default2"
    
    # 检查是否有足够的参数
    if len(sys.argv) > 1:
        param1 = sys.argv[1]
    if len(sys.argv) > 2:
        param2 = sys.argv[2]
    
    # 调用函数，传入参数
    status_code, result_str = some_function(param1, param2)
    
    # 创建结果字典
    result = {
        "status_code": param1,
        "message": result_str
    }
    
    # 输出JSON结果
    print(json.dumps(result, ensure_ascii=False))
    
    # 设置退出码
    sys.exit(status_code)