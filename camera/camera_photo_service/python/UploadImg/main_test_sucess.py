from flask import Flask, request, jsonify
import os
from datetime import datetime
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# 基础上传目录
UPLOAD_FOLDER = 'uploaded_images'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

# 确保基础上传目录存在
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/upload', methods=['POST'])
def upload_image():
    try:
        logger.info(f"Files in request: {request.files}")
        logger.info(f"Form in request: {request.form}")

        # 获取上传类型和值
        upload_type = request.form.get('type', '')  # 'model' 或 'craft'
        upload_value = request.form.get('value', '未分类')

        # 检查文件是否在请求中
        if len(request.files) == 0:
            return jsonify({
                'code': 400,
                'message': 'No file in request'
            }), 400

        # 获取第一个文件
        file = list(request.files.values())[0]

        if file.filename == '':
            return jsonify({
                'code': 400,
                'message': 'No selected file'
            }), 400

        if not allowed_file(file.filename):
            return jsonify({
                'code': 400,
                'message': 'File type not allowed'
            }), 400

        # 创建分类目录
        category_folder = '模型' if upload_type == 'model' else '工艺'
        save_path = os.path.join(UPLOAD_FOLDER, category_folder, upload_value)
        os.makedirs(save_path, exist_ok=True)

        # 生成文件名并保存
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{timestamp}_{file.filename}"
        file_path = os.path.join(save_path, filename)
        
        file.save(file_path)
        logger.info(f'Successfully saved image: {file_path}')

        return jsonify({
            'code': 200,
            'message': 'Image uploaded successfully',
            'filename': filename,
            'path': file_path,
            'type': upload_type,
            'value': upload_value
        }), 200

    except Exception as e:
        logger.error(f'Upload failed: {str(e)}')
        return jsonify({
            'code': 500,
            'message': f'Error during upload: {str(e)}'
        }), 500

@app.route('/status', methods=['GET'])
def status():
    return jsonify({
        'status': 'running',
        'timestamp': datetime.now().isoformat(),
        'upload_folder': UPLOAD_FOLDER
    })

if __name__ == '__main__':
    logger.info('Image upload server starting...')
    logger.info(f'Images will be saved in: {os.path.abspath(UPLOAD_FOLDER)}')

    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )