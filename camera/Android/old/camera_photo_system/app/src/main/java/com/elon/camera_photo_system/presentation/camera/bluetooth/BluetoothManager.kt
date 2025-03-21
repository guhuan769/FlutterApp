package com.elon.camera_photo_system.presentation.camera.bluetooth

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class BluetoothSelfieStickManager(private val context: Context) {
    private val bluetoothManager: BluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter

    private val _isConnected = MutableStateFlow(false)
    val isConnected: StateFlow<Boolean> = _isConnected.asStateFlow()

    private val _connectedDevice = MutableStateFlow<BluetoothDevice?>(null)
    val connectedDevice: StateFlow<BluetoothDevice?> = _connectedDevice.asStateFlow()

    fun isBluetoothEnabled(): Boolean {
        return bluetoothAdapter?.isEnabled == true
    }

    fun scanForDevices(onDeviceFound: (BluetoothDevice) -> Unit) {
        if (!hasBluetoothPermissions()) {
            return
        }

        if (bluetoothAdapter?.isDiscovering == true) {
            bluetoothAdapter.cancelDiscovery()
        }

        bluetoothAdapter?.startDiscovery()
    }

    fun connectToDevice(device: BluetoothDevice) {
        if (!hasBluetoothPermissions()) {
            return
        }

        // 实现蓝牙设备连接逻辑
        // 这里需要根据具体的自拍杆协议实现
        // 连接成功后更新状态
        _isConnected.value = true
        _connectedDevice.value = device
    }

    fun disconnect() {
        if (!hasBluetoothPermissions()) {
            return
        }

        // 断开连接逻辑
        _isConnected.value = false
        _connectedDevice.value = null
    }

    fun triggerCapture(onCapture: () -> Unit) {
        if (!_isConnected.value) {
            return
        }

        // 实现自拍杆触发拍照的逻辑
        onCapture()
    }

    private fun hasBluetoothPermissions(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.BLUETOOTH
        ) == PackageManager.PERMISSION_GRANTED &&
        ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.BLUETOOTH_ADMIN
        ) == PackageManager.PERMISSION_GRANTED &&
        ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED &&
        ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.BLUETOOTH_SCAN
        ) == PackageManager.PERMISSION_GRANTED
    }
} 