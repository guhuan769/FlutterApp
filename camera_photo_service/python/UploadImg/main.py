import asyncio
import base64
from flask import Flask, request, jsonify
import os
from datetime import datetime
import logging
import zipfile
import json
from gmqtt import Client as MQTTClient
import glob
from concurrent.futures import ThreadPoolExecutor
from threading import Lock
from waitress import serve
import uuid
from PIL import Image
import io
import multiprocessing
from threading import Thread

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
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 限制上传大小为100MB
UPLOAD_FOLDER = 'uploaded_images'
ALLOWED_EXTENSIONS = {'jpg', 'jpeg'}
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPIC = "ply/files"
PLY_CHECK_PATH = r"C:\Users\ElonSnyder\Desktop\code\Test"  # PLY文件检查路径

# 创建线程池
executor = ThreadPoolExecutor(max_workers=multiprocessing.cpu_count() * 2)
processing_lock = Lock()
mqtt_client = None

# 确保上传目录存在
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


def check_and_process_ply_files(task_id, project_name=None):
    """检查和处理PLY文件"""
    try:
        ply_files = glob.glob(os.path.join(PLY_CHECK_PATH, "*.ply"))

        if not ply_files:
            logger.info(f"未找到PLY文件 - TaskID: {task_id}")
            send_mqtt_message({
                'type': 'no_ply_files',
                'task_id': task_id,
                'message': '未找到PLY文件，生成失败',
                'project_name': project_name,
                'timestamp': datetime.now().isoformat()
            })
            return False

        # 创建ZIP文件
        zip_path = os.path.join(PLY_CHECK_PATH, f"ply_files_{task_id}.zip")
        with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED) as zipf:
            for ply_file in ply_files:
                zipf.write(ply_file, os.path.basename(ply_file))

        # 读取并发送ZIP文件
        with open(zip_path, 'rb') as file:
            zip_data = file.read()
            zip_base64 = base64.b64encode(zip_data).decode('utf-8')

            message = {
                'type': 'ply_files',
                'task_id': task_id,
                'fileName': os.path.basename(zip_path),
                'fileData': zip_base64,
                'project_name': project_name,
                'timestamp': datetime.now().isoformat()
            }
            send_mqtt_message(message)

        # 清理ZIP文件
        os.remove(zip_path)
        return True

    except Exception as e:
        logger.error(f"处理PLY文件失败: {str(e)}")
        send_mqtt_message({
            'type': 'error',
            'task_id': task_id,
            'error': str(e),
            'project_name': project_name,
            'timestamp': datetime.now().isoformat()
        })
        return False


def send_mqtt_message(message):
    """发送MQTT消息"""
    try:
        if mqtt_client and mqtt_client.is_connected:
            mqtt_client.publish(
                MQTT_TOPIC,
                json.dumps(message),
                qos=1,  # 使用QoS 1确保消息至少被接收一次
                retain=False
            )
            logger.info(f"已发送MQTT消息: {message['type']}")
            return True
        else:
            logger.error("MQTT客户端未连接")
            return False
    except Exception as e:
        logger.error(f"发送MQTT消息失败: {str(e)}")
        return False


@app.route('/upload', methods=['POST'])
async def upload_image():
    """处理文件上传请求"""
    try:
        task_id = str(uuid.uuid4())
        logger.info(f"收到上传请求 - TaskID: {task_id}")

        # 获取基本信息
        try:
            batch_number = int(request.form.get('batch_number', '1'))
            total_batches = int(request.form.get('total_batches', '1'))
        except ValueError as e:
            logger.error(f"批次信息无效: {str(e)}")
            return jsonify({
                'code': 400,
                'message': '批次信息无效'
            }), 400

        upload_type = request.form.get('type', '')
        upload_value = request.form.get('value', '')
        project_info = json.loads(request.form.get('project_info', '{}'))

        logger.info(f"批次: {batch_number}/{total_batches}")
        logger.info(f"上传类型: {upload_type}")
        logger.info(f"上传值: {upload_value}")

        # 创建保存目录结构
        category_folder = '模型' if upload_type == 'model' else '工艺'
        base_save_path = os.path.join(UPLOAD_FOLDER, category_folder, upload_value)
        project_dir = os.path.join(base_save_path, project_info.get('name', 'unknown_project'))

        os.makedirs(base_save_path, exist_ok=True)
        os.makedirs(project_dir, exist_ok=True)

        # 处理上传的文件
        saved_files = []
        files = request.files.getlist('files[]')

        if not files:
            return jsonify({
                'code': 400,
                'message': '没有接收到文件'
            }), 400

        for i, file in enumerate(files):
            try:
                file_content = file.read()
                if not file_content:
                    continue

                # 验证图片文件
                try:
                    image = Image.open(io.BytesIO(file_content))
                    image.verify()
                except Exception as e:
                    logger.error(f"无效的图片文件 {file.filename}: {str(e)}")
                    continue

                # 获取文件信息
                file_info = json.loads(request.form.get(f'file_info_{i}', '{}'))

                # 确定保存路径
                if file_info.get('type') == 'track':
                    track_dir = os.path.join(project_dir, 'tracks', file_info.get('trackName', 'unknown_track'))
                    os.makedirs(track_dir, exist_ok=True)
                    save_path = os.path.join(track_dir, os.path.basename(file_info.get('relativePath', file.filename)))
                else:
                    save_path = os.path.join(project_dir,
                                             os.path.basename(file_info.get('relativePath', file.filename)))

                # 保存文件
                with open(save_path, 'wb') as f:
                    f.write(file_content)

                saved_files.append(save_path)

            except Exception as e:
                logger.error(f"处理文件失败 {file.filename}: {str(e)}")
                continue

        # 如果是最后一个批次，检查PLY文件
        if batch_number == total_batches:
            has_ply = check_and_process_ply_files(task_id, project_info.get('name'))
            return jsonify({
                'code': 200,
                'message': '所有批次上传完成',
                'task_id': task_id,
                'saved_files': len(saved_files),
                'ply_files_found': has_ply
            })
        else:
            return jsonify({
                'code': 200,
                'message': f'批次 {batch_number}/{total_batches} 上传成功',
                'task_id': task_id,
                'saved_files': len(saved_files)
            })

    except Exception as e:
        logger.error(f"上传处理错误: {str(e)}")
        return jsonify({
            'code': 500,
            'message': f'处理错误: {str(e)}'
        }), 500


async def setup_mqtt():
    """设置MQTT客户端"""
    client = MQTTClient("python-server")
    await client.connect(MQTT_BROKER, MQTT_PORT)
    return client


def run_mqtt_client():
    """运行MQTT客户端"""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    global mqtt_client
    mqtt_client = loop.run_until_complete(setup_mqtt())
    loop.run_forever()


@app.route('/status', methods=['GET'])
def status():
    """获取服务器状态"""
    return jsonify({
        'status': 'running',
        'timestamp': datetime.now().isoformat(),
        'mqtt_connected': mqtt_client and mqtt_client.is_connected,
        'worker_threads': len(executor._threads),
        'ply_watch_dir': PLY_CHECK_PATH
    })


def run_server():
    """运行服务器"""
    logger.info('启动服务...')

    # 启动MQTT客户端线程
    mqtt_thread = Thread(target=run_mqtt_client, daemon=True)
    mqtt_thread.start()

    # 启动Web服务器
    serve(app, host='0.0.0.0', port=5000, threads=multiprocessing.cpu_count() * 2)


if __name__ == '__main__':
    run_server()