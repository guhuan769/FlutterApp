// import 'dart:io';
//
// import 'package:auto_route/auto_route.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:image_picker/image_picker.dart';
// import 'util/validator.dart';
// // import 'package:permission_handler/permission_handler.dart';
// import 'package:easy_image_viewer/easy_image_viewer.dart';
// import 'util/custom_dialog.dart';
// // import '../../util/log.dart';
// // import '../../util/toast.dart';
// // import '../navigation/navigation.dart';
// // import '../theme/app_theme.dart';
//
// class CyImage extends StatefulWidget {
//   Widget? icon;
//   String? iconSrc;
//
//   String? uploadedImgUrl;
//   double width;
//   double height;
//
//   String? label;
//   bool? isEdit;
//   String iconSrcOCR;
//
//   final void Function(XFile? file) onImageChoosed;
//   final void Function() onDeleteImage;
//
//   CyImage({
//     super.key,
//     this.icon,
//     this.iconSrc,
//     required this.onImageChoosed,
//     required this.onDeleteImage,
//     this.uploadedImgUrl,
//     this.label = '',
//     this.width = 150,
//     this.height = 86,
//     this.isEdit = true,
//     this.iconSrcOCR = '',
//   });
//
//   @override
//   State<CyImage> createState() => _CyImageState();
// }
//
// class _CyImageState extends State<CyImage> {
//   final ImagePicker _picker = ImagePicker();
//
//   Future<void> _onImageButtonPressed({
//     required BuildContext context,
//     bool isMultiImage = false,
//   }) async {
//     // 是否编辑
//     if (widget.isEdit == false) {
//       if (Validator.isEmpty(widget.uploadedImgUrl)) {
//         return;
//       }
//       showImageViewer(context, Image.network(widget.uploadedImgUrl!).image,
//           swipeDismissible: true, doubleTapZoomable: true);
//       return;
//     }
//     if (kIsWeb) {
//       if (context.mounted) {
//         final XFile? pickedFile =
//             await _picker.pickImage(source: ImageSource.gallery);
//         widget.onImageChoosed(pickedFile);
//       }
//     } else {
//       if (context.mounted) {
//         CustomDialog.chooseCustom(
//           context,
//           title: Text(''),
//           content: Text('使用照相机或者从相册选择图片'),
//           leftText: '相册',
//           rightText: '拍照',
//           onLeftClicked: _onLeftClicked,
//           onRightClicked: _onRightClicked,
//         );
//       }
//     }
//   }
//
//   void _onLeftClicked() async {
//     bool isPhoto = await Validator.isGalleryGranted(context: context);
//     if (isPhoto) {
//       final XFile? pickedFile =
//           await _picker.pickImage(source: ImageSource.gallery);
//       widget.onImageChoosed(pickedFile);
//     }
//   }
//
//   // void _onRightClicked() async {
//   //   if (await Validator.isCameraGranted(context: context)) {
//   //     final XFile? pickedFile =
//   //         await _picker.pickImage(source: ImageSource.camera);
//   //     widget.onImageChoosed(pickedFile);
//   //   }
//   // }
//
//   //新相机
//   void _onRightClicked() async {
//     bool isCamera = await Validator.isCameraGranted(context: context);
//     if (isCamera) {
//       final cameras = await availableCameras();
//       final firstCamera = cameras.first;
//       context.router.push(CustomPhotosRoute(
//           camera: firstCamera,
//           iconSrcOCR: widget.iconSrcOCR,
//           onImageChoosed: (XFile? pickedFile) {
//             widget.onImageChoosed(pickedFile);
//           }));
//     }
//   }
//
//   // 删除图片
//   void _onDelete() async {
//     widget.onDeleteImage();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         _onImageButtonPressed(
//           context: context,
//           isMultiImage: true,
//         );
//       },
//       child: Container(
//         constraints: BoxConstraints(
//           minWidth: widget.width,
//           minHeight: widget.height,
//         ),
//         decoration: BoxDecoration(
//           color: Theme.of(context).extension<AppTheme>()!.colors.background,
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(
//             color: AppTheme.of(context).colors.border,
//             width: 1,
//           ),
//         ),
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             Validator.isEmpty(widget.uploadedImgUrl)
//                 ? Positioned.fill(
//                     child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       widget.iconSrc == null
//                           ? (widget.icon ??
//                               Icon(
//                                 Icons.add,
//                                 size: 20,
//                                 color: Theme.of(context)
//                                     .extension<AppTheme>()!
//                                     .colors
//                                     .textSecond,
//                               ))
//                           : Image.asset(widget.iconSrc!,
//                               width: widget.width,
//                               height: widget.height - 2,
//                               fit: BoxFit.fill),
//                       Validator.isEmpty(widget.label)
//                           ? Container()
//                           : Text(widget.label!),
//                     ],
//                   ))
//                 : ClipRRect(
//                     borderRadius: BorderRadius.circular(4),
//                     child: Image.network(widget.uploadedImgUrl!,
//                         width: widget.width,
//                         height: widget.height,
//                         fit: BoxFit.cover),
//                   ),
//             Visibility(
//               visible:
//                   !Validator.isEmpty(widget.uploadedImgUrl) && widget.isEdit!,
//               child: Positioned(
//                 top: -5,
//                 right: -5,
//                 child: GestureDetector(
//                   onTap: () {
//                     _onDelete();
//                   },
//                   child: Image.asset(
//                     width: 22,
//                     height: 22,
//                     'asset/image/ic_delete.png',
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
