import base64
from flask import Flask, request, jsonify
import os
from datetime import datetime
import logging
import zipfile
import asyncio
from gmqtt import Client as MQTTClient
import glob
from threading import Thread
from waitress import serve
import json

# 配置日志记录
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('app.log')
    ]
)
logger = logging.getLogger(__name__)

# Flask应用配置
app = Flask(__name__)
UPLOAD_FOLDER = 'uploaded_images'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPIC = "ply/files"

# MQTT客户端配置
mqtt_client = None

# 确保上传目录存在
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


def allowed_file(filename):
    """检查文件类型是否允许"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def on_connect(client, flags, rc, properties):
    """MQTT连接回调"""
    logger.info("MQTT客户端连接成功")


async def setup_mqtt():
    """设置MQTT客户端"""
    global mqtt_client
    mqtt_client = MQTTClient("python-server")
    mqtt_client.on_connect = on_connect

    await mqtt_client.connect(MQTT_BROKER)
    return mqtt_client


def run_mqtt_client():
    """运行MQTT客户端"""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(setup_mqtt())
    loop.run_forever()


def send_zip_file(zip_path):
    """读取并发送zip文件"""
    try:
        with open(zip_path, 'rb') as file:
            # 读取zip文件并转换为base64
            zip_data = file.read()
            zip_base64 = base64.b64encode(zip_data).decode('utf-8')

            # 准备消息数据
            message = {
                "type": "ply_files",
                "fileName": os.path.basename(zip_path),
                "fileData": zip_base64,
                "timestamp": datetime.now().isoformat()
            }

            # 发送数据
            if mqtt_client and mqtt_client.is_connected:
                mqtt_client.publish(MQTT_TOPIC, json.dumps(message))
                logger.info(f"已发送zip文件: {os.path.basename(zip_path)}")
                return True
            else:
                logger.error("MQTT客户端未连接")
                return False
    except Exception as e:
        logger.error(f"发送zip文件失败: {str(e)}")
        return False


def check_and_zip_ply_files(directory):
    """检查目录中的.ply文件并压缩"""
    ply_files = glob.glob(os.path.join(directory, "*.ply"))

    if not ply_files:
        logger.info(f"在目录 {directory} 中未找到.ply文件")
        return None

    zip_path = os.path.join(directory, "ply_files.zip")
    with zipfile.ZipFile(zip_path, 'w') as zipf:
        for ply_file in ply_files:
            zipf.write(ply_file, os.path.basename(ply_file))

    logger.info(f"已创建zip文件: {zip_path}")
    return zip_path


@app.route('/upload', methods=['POST'])
def upload_image():
    """处理文件上传请求"""
    try:
        logger.info(f"收到文件: {request.files}")
        logger.info(f"收到表单数据: {request.form}")

        upload_type = request.form.get('type', '')
        upload_value = request.form.get('value', '未分类')

        if len(request.files) == 0:
            return jsonify({
                'code': 400,
                'message': '请求中没有文件'
            }), 400

        file = list(request.files.values())[0]

        if file.filename == '':
            return jsonify({
                'code': 400,
                'message': '未选择文件'
            }), 400

        if not allowed_file(file.filename):
            return jsonify({
                'code': 400,
                'message': '文件类型不允许'
            }), 400

        # 创建保存目录
        category_folder = '模型' if upload_type == 'model' else '工艺'
        save_path = os.path.join(UPLOAD_FOLDER, category_folder, upload_value)
        os.makedirs(save_path, exist_ok=True)

        # 保存上传的文件
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{timestamp}_{file.filename}"
        file_path = os.path.join(save_path, filename)
        file.save(file_path)



        # 检查并压缩指定目录下的.ply文件
        zip_path = check_and_zip_ply_files(r"C:\Users\ElonSnyder\Desktop\code\Test")

        if zip_path:
            # 发送zip文件
            if send_zip_file(zip_path):
                return jsonify({
                    'code': 200,
                    'message': 'zip文件已成功发送',
                    'path': zip_path
                }), 200
            else:
                return jsonify({
                    'code': 500,
                    'message': '发送zip文件失败'
                }), 500
        else:
            return jsonify({
                'code': 404,
                'message': '未找到.ply文件'
            }), 404

    except Exception as e:
        logger.error(f'上传失败: {str(e)}')
        return jsonify({
            'code': 500,
            'message': f'处理错误: {str(e)}'
        }), 500


@app.route('/status', methods=['GET'])
def status():
    """获取服务器状态"""
    return jsonify({
        'status': 'running',
        'timestamp': datetime.now().isoformat(),
        'upload_folder': UPLOAD_FOLDER,
        'mqtt_connected': mqtt_client and mqtt_client.is_connected
    })


def run_server():
    """运行服务器"""
    logger.info('图片上传服务器启动中...')
    logger.info(f'图片将保存在: {os.path.abspath(UPLOAD_FOLDER)}')

    # 在单独的线程中运行MQTT客户端
    mqtt_thread = Thread(target=run_mqtt_client)
    mqtt_thread.daemon = True
    mqtt_thread.start()

    # 使用 Waitress 服务器
    logger.info('Waitress服务器启动中...')
    serve(app, host='0.0.0.0', port=5000, threads=4)


if __name__ == '__main__':
    run_server()