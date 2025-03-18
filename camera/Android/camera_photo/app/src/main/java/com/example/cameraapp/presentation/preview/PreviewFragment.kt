package com.example.cameraapp.presentation.preview

import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.navigation.fragment.findNavController
import androidx.navigation.fragment.navArgs
import com.example.cameraapp.databinding.FragmentPreviewBinding
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class PreviewFragment : Fragment() {

    private var _binding: FragmentPreviewBinding? = null
    private val binding get() = _binding!!
    private val args: PreviewFragmentArgs by navArgs()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentPreviewBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupUI()
        setupListeners()
    }

    private fun setupUI() {
        // 显示拍摄的照片
        val photoUri = Uri.parse(args.photoUri)
        binding.photoView.setImageURI(photoUri)
    }

    private fun setupListeners() {
        // 重新拍照按钮
        binding.retakeButton.setOnClickListener {
            findNavController().popBackStack()
        }
        
        // 保存按钮
        binding.saveButton.setOnClickListener {
            // 照片已经保存到MediaStore，只需显示成功消息
            binding.saveButton.isEnabled = false
            binding.saveButton.text = "已保存"
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
} 