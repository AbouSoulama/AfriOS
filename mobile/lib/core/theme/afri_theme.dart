import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'afri_colors.dart';

class AfriTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AfriColors.teal,
        primary: AfriColors.teal,
        secondary: AfriColors.gold,
        surface: Colors.white,
        error: AfriColors.error,
      ),
      scaffoldBackgroundColor: AfriColors.mist,
      splashFactory: InkSparkle.splashFactory,
    );

    final display = GoogleFonts.soraTextTheme(base.textTheme);
    final body = GoogleFonts.dmSansTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AfriColors.ink,
          letterSpacing: -1.6,
          height: 1.04,
        ),
        displayMedium: display.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AfriColors.ink,
          letterSpacing: -1.1,
          height: 1.06,
        ),
        displaySmall: display.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AfriColors.ink,
          letterSpacing: -0.8,
          height: 1.08,
        ),
        headlineLarge: display.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AfriColors.ink,
          letterSpacing: -0.8,
          height: 1.12,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AfriColors.ink,
          letterSpacing: -0.6,
          height: 1.16,
        ),
        headlineSmall: display.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AfriColors.ink,
          letterSpacing: -0.4,
        ),
        titleLarge: display.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AfriColors.ink,
          letterSpacing: -0.3,
        ),
        titleMedium: body.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AfriColors.ink,
        ),
        titleSmall: body.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AfriColors.slate,
          letterSpacing: 0.2,
        ),
        bodyLarge: body.bodyLarge?.copyWith(color: AfriColors.ink, height: 1.5),
        bodyMedium:
            body.bodyMedium?.copyWith(color: AfriColors.slate, height: 1.5),
        bodySmall: body.bodySmall
            ?.copyWith(color: AfriColors.slateLight, height: 1.45),
        labelLarge: body.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AfriColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AfriColors.ink,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AfriRadius.rLg),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: AfriRadius.rMd,
          borderSide: const BorderSide(color: AfriColors.mistDeep, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AfriRadius.rMd,
          borderSide: const BorderSide(color: AfriColors.mistDeep, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AfriRadius.rMd,
          borderSide: const BorderSide(color: AfriColors.teal, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AfriRadius.rMd,
          borderSide: const BorderSide(color: AfriColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AfriRadius.rMd,
          borderSide: const BorderSide(color: AfriColors.error, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: GoogleFonts.dmSans(
            color: AfriColors.slate, fontWeight: FontWeight.w600),
        floatingLabelStyle: GoogleFonts.dmSans(
            color: AfriColors.tealDark, fontWeight: FontWeight.w700),
        hintStyle: GoogleFonts.dmSans(color: AfriColors.slateLight),
        helperStyle:
            GoogleFonts.dmSans(fontSize: 12, color: AfriColors.slateLight),
        prefixIconColor: AfriColors.slate,
        suffixIconColor: AfriColors.slate,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AfriColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle:
            GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: AfriRadius.rMd),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AfriColors.tealDark : AfriColors.slateLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? AfriColors.tealDark : AfriColors.slateLight,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AfriColors.mistDeep,
        dragHandleSize: Size(40, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AfriRadius.xxl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AfriRadius.rXl),
        titleTextStyle: GoogleFonts.sora(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AfriColors.ink,
          letterSpacing: -0.3,
        ),
        contentTextStyle:
            GoogleFonts.dmSans(color: AfriColors.slate, height: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AfriColors.ink,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        contentTextStyle: GoogleFonts.dmSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: AfriRadius.rSm),
      ),
      dividerTheme: const DividerThemeData(
        color: AfriColors.line,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AfriColors.tealSoft,
        checkmarkColor: AfriColors.tealDark,
        labelStyle:
            GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: AfriRadius.rSm,
          side: const BorderSide(color: AfriColors.mistDeep),
        ),
        side: BorderSide.none,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AfriColors.teal,
        linearMinHeight: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : AfriColors.slateLight),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AfriColors.teal
                : AfriColors.mistDeep),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AfriColors.slate,
        titleTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AfriColors.ink,
        ),
        subtitleTextStyle:
            GoogleFonts.dmSans(fontSize: 13, color: AfriColors.slate),
        shape: RoundedRectangleBorder(borderRadius: AfriRadius.rMd),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AfriColors.ink,
          borderRadius: AfriRadius.rXs,
        ),
        textStyle: GoogleFonts.dmSans(color: Colors.white, fontSize: 12),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AfriColors.tealDark,
          textStyle:
              GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: AfriRadius.rSm),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AfriRadius.rXl),
        headerBackgroundColor: AfriColors.teal,
        headerForegroundColor: Colors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
