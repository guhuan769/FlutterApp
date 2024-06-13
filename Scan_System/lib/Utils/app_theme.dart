// import 'package:flutter/material.dart';
// import 'package:lianyun_driver/presenter/theme/colors.dart';
// import 'package:lianyun_driver/presenter/theme/styles.dart';
// import 'package:lianyun_driver/presenter/theme/typography.dart';
//
// // 整个app主题配置都在这里
// class AppTheme extends ThemeExtension<AppTheme> {
//   final String name;
//   final Brightness brightness;
//   final AppThemeColors colors;
//   final AppThemeTypography typographies;
//   final AppThemeStyles styles;
//
//   static AppTheme of(BuildContext context) {
//     return Theme.of(context).extension<AppTheme>()!;
//   }
//
//   const AppTheme({
//     required this.name,
//     required this.brightness,
//     required this.colors,
//     this.styles = const AppThemeStyles(),
//     this.typographies = const AppThemeTypography(),
//   });
//
//   ColorScheme get baseColorScheme => brightness == Brightness.light //
//       ? const ColorScheme.light()
//       : const ColorScheme.dark();
//
//   BoxDecoration get baseContainer => BoxDecoration(
//         color: colors.backgroundSecond,
//         borderRadius: BorderRadius.circular(8),
//       );
//
//   ThemeData get themeData => ThemeData(
//         useMaterial3: false,
//         platform: TargetPlatform.iOS,
//         extensions: [this],
//         brightness: brightness,
//         primarySwatch: colors.primarySwatch,
//         primaryColor: colors.primary,
//         unselectedWidgetColor: colors.hint,
//         disabledColor: colors.disabled,
//         scaffoldBackgroundColor: colors.background,
//         hintColor: colors.hint,
//         dividerColor: colors.border,
//         colorScheme: baseColorScheme.copyWith(
//           primary: colors.primary,
//           onPrimary: colors.textOnPrimary,
//           secondary: colors.secondary,
//           onSecondary: colors.textOnPrimary,
//           error: colors.error,
//           shadow: colors.border,
//         ),
//         appBarTheme: AppBarTheme(
//           elevation: 0,
//           titleTextStyle: typographies.heading.copyWith(
//             color: colors.text,
//           ),
//           centerTitle: true,
//           color: Colors.transparent,
//           foregroundColor: colors.text,
//           surfaceTintColor: colors.text,
//         ),
//         tabBarTheme: TabBarTheme(
//           indicatorColor: colors.primary,
//           indicatorSize: TabBarIndicatorSize.label,
//           indicator: BoxDecoration(
//             border: Border(
//               bottom: BorderSide(
//                 color: colors.primary,
//                 width: 4,
//               ),
//             ),
//           ),
//           labelColor: colors.primary,
//           unselectedLabelColor: colors.text,
//           labelStyle: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//           ),
//           unselectedLabelStyle: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         filledButtonTheme: FilledButtonThemeData(
//           style: styles.buttonLarge.copyWith(
//             backgroundColor: MaterialStateProperty.resolveWith((states) {
//               return states.contains(MaterialState.disabled)
//                   ? colors.disabled
//                   : null; // Defer to the widget's default.
//             }),
//             foregroundColor: MaterialStateProperty.resolveWith((states) {
//               return states.contains(MaterialState.disabled)
//                   ? colors.disabled
//                   : null; // Defer to the widget's default.
//             }),
//           ),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: styles.buttonLarge.copyWith(
//             backgroundColor: MaterialStateProperty.resolveWith((states) {
//               return states.contains(MaterialState.disabled)
//                   ? colors.disabled
//                   : null; // Defer to the widget's default.
//             }),
//             foregroundColor: MaterialStateProperty.resolveWith((states) {
//               return states.contains(MaterialState.disabled)
//                   ? colors.disabled
//                   : null; // Defer to the widget's default.
//             }),
//           ),
//         ),
//         outlinedButtonTheme: OutlinedButtonThemeData(
//           style: styles.buttonLarge.copyWith(
//             side: MaterialStateProperty.resolveWith((states) {
//               return states.contains(MaterialState.disabled)
//                   ? BorderSide(color: colors.disabled)
//                   : null;
//             }),
//             foregroundColor: MaterialStateProperty.resolveWith((states) {
//               return states.contains(MaterialState.disabled)
//                   ? colors.disabled
//                   : null; // Defer to the widget's default.
//             }),
//           ),
//         ),
//         textButtonTheme: TextButtonThemeData(
//           style: styles.buttonText.copyWith(),
//         ),
//         // 输入框
//         inputDecorationTheme: InputDecorationTheme(
//           contentPadding:
//               const EdgeInsets.symmetric(vertical: 10, horizontal: 42),
//           filled: true,
//           fillColor: Colors.transparent,
//           hintStyle: typographies.bodySmall.copyWith(
//               fontWeight: FontWeight.w500,
//               color: colors.text.withOpacity(0.4),
//               fontSize: 14),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(100),
//             borderSide: BorderSide.none,
//           ),
//           prefixIconColor: colors.text,
//           suffixIconColor: colors.text,
//         ),
//         checkboxTheme: CheckboxThemeData(
//           visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
//           fillColor: MaterialStateProperty.resolveWith((states) {
//             return states.contains(MaterialState.disabled)
//                 ? colors.disabled
//                 : states.contains(MaterialState.selected)
//                     ? colors.primary
//                     : null;
//           }),
//           checkColor: MaterialStateProperty.resolveWith((states) {
//             return states.contains(MaterialState.disabled)
//                 ? colors.disabled
//                 : Colors.white;
//           }),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
//           side: BorderSide(color: colors.primary, width: 2),
//         ),
//         radioTheme: const RadioThemeData(
//           visualDensity: VisualDensity(horizontal: -4, vertical: -4),
//         ),
//         floatingActionButtonTheme: FloatingActionButtonThemeData(
//           backgroundColor: colors.secondary,
//           foregroundColor: colors.textOnPrimary,
//           elevation: 0,
//         ),
//         dividerTheme: DividerThemeData(
//           color: colors.border,
//           thickness: 1,
//           space: 1,
//         ),
//       );
//
//   @override
//   AppTheme copyWith({
//     String? name,
//     Brightness? brightness,
//     AppThemeColors? colors,
//     AppThemeTypography? typographies,
//     AppThemeStyles? styles,
//   }) {
//     return AppTheme(
//       brightness: brightness ?? this.brightness,
//       name: name ?? this.name,
//       colors: colors ?? this.colors,
//       typographies: typographies ?? this.typographies,
//       styles: styles ?? this.styles,
//     );
//   }
//
//   @override
//   AppTheme lerp(covariant ThemeExtension<AppTheme>? other, double t) {
//     if (other is! AppTheme) {
//       return this;
//     }
//     return AppTheme(
//       name: name,
//       brightness: brightness,
//       colors: colors.lerp(other.colors, t),
//       typographies: typographies.lerp(other.typographies, t),
//       styles: styles,
//     );
//   }
// }
