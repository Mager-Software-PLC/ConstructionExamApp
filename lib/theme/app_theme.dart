import 'package:flutter/material.dart';

// App color constants
class AppColors {
  // Light theme colors - Yellow/Amber theme (matching shadcn yellow)
  static const Color lightPrimary = Color(0xFFEAB308); // Amber 500 - Golden yellow (matches oklch(0.70 0.18 90))
  static const Color lightPrimaryVariant = Color(0xFFFCD34D); // Amber 300 - Lighter yellow
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFFEFDF6); // Light yellowish tint
  static const Color lightOnSurface = Color(0xFF1F1F1F);
  
  // Dark theme colors - Yellow/Amber theme (matching shadcn yellow)
  static const Color darkPrimary = Color(0xFFFBBF24); // Amber 400 - Bright yellow (matches oklch(0.75 0.20 90))
  static const Color darkPrimaryVariant = Color(0xFFFCD34D); // Amber 300 - Lighter yellow
  static const Color darkSurface = Color(0xFF1F1E16); // Dark yellowish surface
  static const Color darkBackground = Color(0xFF14130F); // Very dark yellowish background
  static const Color darkOnSurface = Color(0xFFFEF3C7); // Light yellowish text
  
  // Semantic colors (same for both themes)
  static const Color success = Color(0xFF10B981); // Green for success
  static const Color warning = Color(0xFFF59E0B); // Amber/Orange
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue
  
  // Difficulty colors
  static const Color difficultyEasy = Color(0xFF10B981); // Green for easy
  static const Color difficultyMedium = Color(0xFFF59E0B); // Amber/Orange for medium
  static const Color difficultyHard = Color(0xFFEF4444); // Red for hard
}

// Typography scale
class AppTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.2,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.5,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.5,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
}

// Spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Border radius constants
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 9999.0;
}

// Elevation constants
class AppElevation {
  static const double none = 0.0;
  static const double sm = 1.0;
  static const double md = 2.0;
  static const double lg = 4.0;
  static const double xl = 8.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.lightPrimary,
      secondary: AppColors.lightPrimaryVariant,
      tertiary: AppColors.lightPrimary.withOpacity(0.6),
      error: AppColors.error,
      surface: AppColors.lightSurface,
      background: AppColors.lightBackground,
      onPrimary: const Color(0xFF1F1F1F), // Dark text on yellow (matches oklch(0.20 0.02 90))
      onSecondary: const Color(0xFF1F1F1F), // Dark text on yellow
      onTertiary: const Color(0xFF1F1F1F), // Dark text on yellow
      onError: Colors.white,
      onSurface: AppColors.lightOnSurface,
      onBackground: AppColors.lightOnSurface,
      primaryContainer: AppColors.lightPrimary.withOpacity(0.1),
      secondaryContainer: AppColors.lightPrimaryVariant.withOpacity(0.1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.1),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.lightOnSurface,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: AppColors.lightOnSurface,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: AppColors.lightOnSurface,
          size: 24,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: AppElevation.md,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: colorScheme.onPrimary,
          elevation: AppElevation.md,
          shadowColor: AppColors.lightPrimary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.lightPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side: BorderSide(
            color: AppColors.lightPrimary,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.lightPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.lightPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.38),
            width: 1,
          ),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: colorScheme.error,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: AppElevation.lg,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: colorScheme.onPrimary,
        elevation: AppElevation.lg,
        highlightElevation: AppElevation.xl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.12),
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
        titleTextStyle: AppTypography.titleMedium,
        subtitleTextStyle: AppTypography.bodyMedium,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        deleteIconColor: colorScheme.onSurface,
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        selectedColor: AppColors.lightPrimary.withOpacity(0.2),
        secondarySelectedColor: AppColors.lightPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        labelStyle: AppTypography.labelMedium,
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: colorScheme.onPrimary,
        ),
        brightness: Brightness.light,
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.lightPrimary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: IconThemeData(
        color: colorScheme.onPrimary,
        size: 24,
      ),
      
      // Typography
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: colorScheme.surface,
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: AppElevation.xl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AppElevation.lg,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.grey.shade300;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.lightPrimary;
          }
          return Colors.grey.shade400;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.lightPrimary;
          }
          return null;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.lightPrimary;
          }
          return colorScheme.onSurface;
        }),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkPrimaryVariant,
      tertiary: AppColors.darkPrimary.withOpacity(0.6),
      error: AppColors.error,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
      onPrimary: AppColors.darkBackground,
      onSecondary: AppColors.darkBackground,
      onTertiary: AppColors.darkBackground,
      onError: Colors.white,
      onSurface: AppColors.darkOnSurface,
      onBackground: AppColors.darkOnSurface,
      primaryContainer: AppColors.darkPrimary.withOpacity(0.2),
      secondaryContainer: AppColors.darkPrimaryVariant.withOpacity(0.2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.darkOnSurface,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkOnSurface,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: AppColors.darkOnSurface,
          size: 24,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: AppElevation.md,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: colorScheme.onPrimary,
          elevation: AppElevation.md,
          shadowColor: AppColors.darkPrimary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.darkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: BorderSide(
            color: AppColors.darkPrimary,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.darkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.darkPrimary,
            width: 2.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.38),
            width: 1.5,
          ),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: colorScheme.error,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: AppElevation.lg,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: colorScheme.onPrimary,
        elevation: AppElevation.lg,
        highlightElevation: AppElevation.xl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.12),
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
        titleTextStyle: AppTypography.titleMedium,
        subtitleTextStyle: AppTypography.bodyMedium,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        deleteIconColor: colorScheme.onSurface,
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        selectedColor: AppColors.darkPrimary.withOpacity(0.2),
        secondarySelectedColor: AppColors.darkPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        labelStyle: AppTypography.labelMedium,
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: colorScheme.onPrimary,
        ),
        brightness: Brightness.dark,
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.darkPrimary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: IconThemeData(
        color: colorScheme.onPrimary,
        size: 24,
      ),
      
      // Typography
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: colorScheme.surface,
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: AppElevation.xl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AppElevation.lg,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.darkOnSurface;
          }
          return Colors.grey.shade600;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.darkPrimary;
          }
          return Colors.grey.shade700;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.darkPrimary;
          }
          return null;
        }),
        checkColor: MaterialStateProperty.all(AppColors.darkOnSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.darkPrimary;
          }
          return colorScheme.onSurface;
        }),
      ),
    );
  }
}

