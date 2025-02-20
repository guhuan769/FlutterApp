import asyncio
import json
import os
import base64
from datetime import datetime
from typing import Optional
import zipfile
import glob
from gmqtt import Client as MQTTClient
from gmqtt.mqtt.constants import MQTTv5
from flask import Flask, request, jsonify

app = Flask(__name__)
UPLOAD_FOLDER = 'uploaded_data'
PLY_CHECK_FOLDERS = ['models', 'scans', 'reconstructions']  # Add your specific folders
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPIC = "ply/files"

class MQTTHandler:
    def __init__(self):
        self.client = None
        self.connected = False

    async def connect(self):
        self.client = MQTTClient("python-server", version=MQTTv5)

        def on_connect(client, flags, rc, properties):
            print("MQTT Connected")
            self.connected = True

        def on_message(client, topic, payload, qos, properties):
            try:
                data = json.loads(payload.decode())
                if data.get('type') == 'ack':
                    print(f"Received acknowledgment from client: {data}")
            except Exception as e:
                print(f"Error processing message: {e}")

        def on_disconnect(client, packet, exc=None):
            self.connected = False

        self.client.on_connect = on_connect
        self.client.on_message = on_message
        self.client.on_disconnect = on_disconnect

        await self.client.connect(MQTT_BROKER, MQTT_PORT)

    async def publish_ply_data(self, project_id: str, zip_path: str, project_info: dict):
        if not self.connected:
            print("MQTT not connected")
            return

        try:
            with open(zip_path, 'rb') as f:
                zip_data = f.read()
                zip_base64 = base64.b64encode(zip_data).decode('utf-8')

            message = {
                "type": "ply_data",
                "projectId": project_id,
                "timestamp": datetime.now().isoformat(),
                "fileName": os.path.basename(zip_path),
                "fileData": zip_base64,
                "projectInfo": project_info
            }

            properties = {
                'content_type': 'application/zip',
                'response_topic': f"{MQTT_TOPIC}/ack/{project_id}",
                'correlation_data': project_id.encode()
            }

            await self.client.publish(
                MQTT_TOPIC,
                json.dumps(message).encode(),
                qos=2,
                properties=properties
            )
            print(f"Published PLY data for project {project_id}")

        except Exception as e:
            print(f"Error publishing PLY data: {e}")

mqtt_handler = MQTTHandler()

def check_for_ply_files(project_path: str) -> list:
    ply_files = []
    for folder in PLY_CHECK_FOLDERS:
        search_path = os.path.join(project_path, folder, "**/*.ply")
        ply_files.extend(glob.glob(search_path, recursive=True))
    return ply_files

def create_ply_zip(ply_files: list, project_id: str) -> Optional[str]:
    if not ply_files:
        return None

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    zip_path = os.path.join(UPLOAD_FOLDER, f"ply_{project_id}_{timestamp}.zip")

    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for ply_file in ply_files:
            arcname = os.path.basename(ply_file)
            zipf.write(ply_file, arcname)

    return zip_path

@app.route('/upload/project', methods=['POST'])
async def upload_project():
    try:
        if 'project_info' not in request.form:
            return jsonify({'error': 'Missing project info'}), 400

        project_info = json.loads(request.form['project_info'])
        project_id = project_info.get('id')

        # Save project files
        project_path = os.path.join(UPLOAD_FOLDER, 'projects', project_id)
        os.makedirs(project_path, exist_ok=True)

        # Handle file uploads
        for file in request.files.getlist('files[]'):
            if file and file.filename:
                file_path = os.path.join(project_path, file.filename)
                os.makedirs(os.path.dirname(file_path), exist_ok=True)
                file.save(file_path)

        # Check for PLY files
        ply_files = check_for_ply_files(project_path)
        if ply_files:
            zip_path = create_ply_zip(ply_files, project_id)
            if zip_path:
                await mqtt_handler.publish_ply_data(project_id, zip_path, project_info)
                os.remove(zip_path)  # Clean up zip file after sending
        else:
            print(f"No PLY files found for project {project_id}")
            # Notify MQTT clients about missing PLY files
            await mqtt_handler.publish_ply_data(
                project_id,
                None,
                {**project_info, "status": "no_ply_files"}
            )

        return jsonify({
            'status': 'success',
            'project_id': project_id,
            'ply_files_found': bool(ply_files)
        })

    except Exception as e:
        print(f"Error in upload_project: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    loop = asyncio.get_event_loop()
    loop.run_until_complete(mqtt_handler.connect())
    app.run(host='0.0.0.0', port=5000)