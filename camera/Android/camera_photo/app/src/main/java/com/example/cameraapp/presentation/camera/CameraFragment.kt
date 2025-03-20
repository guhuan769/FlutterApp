package com.example.cameraapp.presentation.camera

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import com.example.cameraapp.R
import com.example.cameraapp.databinding.FragmentCameraBinding
import com.example.cameraapp.domain.model.CameraState
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class CameraFragment : Fragment() {

    private var _binding: FragmentCameraBinding? = null
    private val binding get() = _binding!!
    private val viewModel: CameraViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentCameraBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupCamera()
        setupListeners()
        observeViewModel()
    }

    private fun setupCamera() {
        viewModel.initializeCamera(binding.viewFinder)
    }

    private fun setupListeners() {
        // 拍照按钮
        binding.captureButton.setOnClickListener {
            viewModel.takePhoto(requireContext())
        }
        
        // 切换摄像头按钮
        binding.switchButton.setOnClickListener {
            viewModel.toggleCamera()
        }
    }

    private fun observeViewModel() {
        viewModel.cameraState.observe(viewLifecycleOwner) { state ->
            when (state) {
                is CameraState.Initial -> {
                    // 初始状态
                    binding.progressBar.visibility = View.GONE
                }
                is CameraState.Loading -> {
                    // 加载状态
                    binding.progressBar.visibility = View.VISIBLE
                }
                is CameraState.Ready -> {
                    // 相机准备好状态
                    binding.progressBar.visibility = View.GONE
                    binding.captureButton.isEnabled = true
                }
                is CameraState.Error -> {
                    // 错误状态
                    binding.progressBar.visibility = View.GONE
                    // 显示错误提示
                }
                is CameraState.PhotoCaptured -> {
                    // 照片已捕获状态
                    binding.progressBar.visibility = View.GONE
                    // 导航到预览界面

                    // 使用Bundle传递参数
                    val bundle = Bundle().apply {
                        putString("imageUri", state.uri.toString())
                    }
                    // 使用ID直接导航并传递参数
                    findNavController().navigate(
                        R.id.action_cameraFragment_to_previewFragment,
                        bundle
                    )
                }
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
} 