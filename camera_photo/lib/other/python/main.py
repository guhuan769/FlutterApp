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
import shutil
from concurrent.futures import ThreadPoolExecutor

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
UPLOAD_FOLDER = 'uploaded_data'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPIC = "ply/files"

# MQTT客户端配置
mqtt_client = None
executor = ThreadPoolExecutor(max_workers=4)  # 用于处理并发上传

# 确保上传目录存在
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    """检查文件类型是否允许"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

async def setup_mqtt():
    """设置MQTT客户端"""
    global mqtt_client
    mqtt_client = MQTTClient("python-server")
    mqtt_client.on_connect = lambda client, flags, rc, properties: logger.info("MQTT客户端连接成功")
    await mqtt_client.connect(MQTT_BROKER)
    return mqtt_client

def process_project_upload(project_data, files, project_info):
    """处理单个项目的上传"""
    try:
        project_name = project_info.get('name', 'unnamed_project')
        project_save_path = os.path.join(UPLOAD_FOLDER, 'projects', project_name)
        os.makedirs(project_save_path, exist_ok=True)

        # 保存所有文件
        for file_data in files:
            relative_path = file_data['path']
            file_content = file_data['content']
            save_path = os.path.join(project_save_path, relative_path)
            os.makedirs(os.path.dirname(save_path), exist_ok=True)

            with open(save_path, 'wb') as f:
                f.write(file_content)

        # 创建项目配置文件
        config_path = os.path.join(project_save_path, 'project.json')
        with open(config_path, 'w') as f:
            json.dump(project_info, f, indent=2)

        # 创建压缩包
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        zip_path = os.path.join(UPLOAD_FOLDER, f"{project_name}_{timestamp}.zip")

        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, _, files in os.walk(project_save_path):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, project_save_path)
                    zipf.write(file_path, arcname)

        # 发送到MQTT
        if mqtt_client and mqtt_client.is_connected:
            with open(zip_path, 'rb') as f:
                zip_data = f.read()
                zip_base64 = base64.b64encode(zip_data).decode('utf-8')

                message = {
                    "type": "project_data",
                    "projectId": project_info.get('id'),
                    "projectName": project_name,
                    "fileName": os.path.basename(zip_path),
                    "fileData": zip_base64,
                    "timestamp": datetime.now().isoformat(),
                    "projectInfo": project_info
                }

                mqtt_client.publish(
                    MQTT_TOPIC,
                    json.dumps(message)
                )

        # 清理临时文件
        shutil.rmtree(project_save_path)
        os.remove(zip_path)

        return {
            "status": "success",
            "projectId": project_info.get('id'),
            "message": "项目上传成功"
        }

    except Exception as e:
        logger.error(f"项目 {project_name} 处理失败: {str(e)}")
        return {
            "status": "error",
            "projectId": project_info.get('id'),
            "message": str(e)
        }

@app.route('/upload/project', methods=['POST'])
def upload_project():
    """处理项目上传请求"""
    try:
        if 'project_info' not in request.form:
            return jsonify({
                'code': 400,
                'message': '缺少项目信息'
            }), 400

        project_info = json.loads(request.form['project_info'])

        # 处理文件
        if 'files[]' not in request.files:
            return jsonify({
                'code': 400,
                'message': '没有文件上传'
            }), 400

        files = []
        for file in request.files.getlist('files[]'):
            if file and file.filename:
                file_content = file.read()
                files.append({
                    'path': file.filename,
                    'content': file_content
                })

        # 异步处理项目上传
        result = executor.submit(
            process_project_upload,
            files,
            project_info
        ).result()

        if result['status'] == 'success':
            return jsonify({
                'code': 200,
                'message': result['message'],
                'projectId': result['projectId']
            })
        else:
            return jsonify({
                'code': 500,
                'message': result['message'],
                'projectId': result['projectId']
            }), 500

    except Exception as e:
        logger.error(f'项目上传失败: {str(e)}')
        return jsonify({
            'code': 500,
            'message': f'处理错误: {str(e)}'
        }), 500

@app.route('/upload/photo', methods=['POST'])
def upload_photo():
    """处理单个照片上传请求"""
    try:
        project_id = request.form.get('project_id')
        track_id = request.form.get('track_id')

        if not request.files:
            return jsonify({
                'code': 400,
                'message': '请求中没有文件'
            }), 400

        file = list(request.files.values())[0]
        if not file or not file.filename:
            return jsonify({
                'code': 400,
                'message': '未选择文件'
            }), 400

        if not allowed_file(file.filename):
            return jsonify({
                'code': 400,
                'message': '文件类型不允许'
            }), 400

        # 构建保存路径
        base_path = os.path.join(UPLOAD_FOLDER, 'projects', project_id)
        if track_id:
            save_path = os.path.join(base_path, 'tracks', track_id)
        else:
            save_path = base_path

        os.makedirs(save_path, exist_ok=True)

        # 保存文件
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{timestamp}_{file.filename}"
        file_path = os.path.join(save_path, filename)
        file.save(file_path)

        return jsonify({
            'code': 200,
            'message': '照片上传成功',
            'path': file_path
        })

    except Exception as e:
        logger.error(f'照片上传失败: {str(e)}')
        return jsonify({
            'code': 500,
            'message': f'处理错误: {str(e)}'
        }), 500

@app.route('/projects/<project_id>/status', methods=['GET'])
def get_project_status(project_id):
    """获取项目状态"""
    try:
        project_path = os.path.join(UPLOAD_FOLDER, 'projects', project_id)
        if not os.path.exists(project_path):
            return jsonify({
                'code': 404,
                'message': '项目不存在'
            }), 404

        # 获取项目信息
        config_path = os.path.join(project_path, 'project.json')
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                project_info = json.load(f)
        else:
            project_info = {'id': project_id}

        # 统计照片数量
        photo_count = len([f for f in glob.glob(os.path.join(project_path, '**/*.jpg'), recursive=True)])

        # 统计轨迹数量
        tracks_path = os.path.join(project_path, 'tracks')
        track_count = len([d for d in os.listdir(tracks_path)]) if os.path.exists(tracks_path) else 0

        return jsonify({
            'code': 200,
            'project_info': project_info,
            'photo_count': photo_count,
            'track_count': track_count,
            'last_modified': datetime.fromtimestamp(os.path.getmtime(project_path)).isoformat()
        })

    except Exception as e:
        logger.error(f'获取项目状态失败: {str(e)}')
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
        'mqtt_connected': mqtt_client and mqtt_client.is_connected,
        'version': '2.0.0'
    })

def run_mqtt_client():
    """运行MQTT客户端"""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(setup_mqtt())
    loop.run_forever()

def run_server():
    """运行服务器"""
    logger.info('项目管理服务器启动中...')
    logger.info(f'文件将保存在: {os.path.abspath(UPLOAD_FOLDER)}')

    # 在单独的线程中运行MQTT客户端
    mqtt_thread = Thread(target=run_mqtt_client)
    mqtt_thread.daemon = True
    mqtt_thread.start()

    # 使用 Waitress 服务器
    logger.info('Waitress服务器启动中...')
    serve(app, host='0.0.0.0', port=5000, threads=4)

if __name__ == '__main__':
    run_server()