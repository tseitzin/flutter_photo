import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker_desktop/file_picker_desktop.dart' as file_picker;
import 'package:intl/intl.dart';
import '../widgets/dialogs/images_dialog.dart';
import '../widgets/dialogs/errors_dialog.dart';
import '../../domain/repositories/directory_repository.dart';
import '../../data/models/directory_stats.dart';

@immutable
class PhotoAnalyzerState {
  final bool isLoading;
  final String? selectedDirectory;
  final List<DirectoryStats> directoryStats;
  final int scannedFiles;
  final int scannedDirs;
  final int totalDirs;
  final int imagesFound;
  final Duration elapsedTime;
  final List<String> errors;

  const PhotoAnalyzerState({
    this.isLoading = false,
    this.selectedDirectory,
    this.directoryStats = const [],
    this.scannedFiles = 0,
    this.scannedDirs = 0,
    this.totalDirs = 0,
    this.imagesFound = 0,
    this.elapsedTime = Duration.zero,
    this.errors = const [],
  });

  int get totalImages =>
      directoryStats.fold(0, (sum, stats) => sum + stats.imageCount);
  int get errorCount => errors.length;

  PhotoAnalyzerState copyWith({
    bool? isLoading,
    String? selectedDirectory,
    List<DirectoryStats>? directoryStats,
    int? scannedFiles,
    int? scannedDirs,
    int? totalDirs,
    int? imagesFound,
    Duration? elapsedTime,
    List<String>? errors,
  }) {
    return PhotoAnalyzerState(
      isLoading: isLoading ?? this.isLoading,
      selectedDirectory: selectedDirectory ?? this.selectedDirectory,
      directoryStats: directoryStats ?? this.directoryStats,
      scannedFiles: scannedFiles ?? this.scannedFiles,
      scannedDirs: scannedDirs ?? this.scannedDirs,
      totalDirs: totalDirs ?? this.totalDirs,
      imagesFound: imagesFound ?? this.imagesFound,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      errors: errors ?? this.errors,
    );
  }
}

class PhotoAnalyzerNotifier extends StateNotifier<PhotoAnalyzerState> {
  final DirectoryRepository _repository;
  DateTime? _scanStartTime;

  PhotoAnalyzerNotifier(this._repository) : super(const PhotoAnalyzerState());

  Future<void> pickDirectory(BuildContext context) async {
    try {
      final String? selectedDirectory = await file_picker.getDirectoryPath();

      if (selectedDirectory == null) {
        print('No directory selected'); // Debug log
        return;
      }

      state = state.copyWith(
        selectedDirectory: selectedDirectory,
        isLoading: true,
        directoryStats: [],
        errors: [],
        scannedFiles: 0,
        scannedDirs: 0,
        totalDirs: 0,
        imagesFound: 0,
        elapsedTime: Duration.zero,
      );

      _scanStartTime = DateTime.now();
      await _scanDirectory(selectedDirectory);
    } catch (e) {
      print('Error picking directory: $e'); // Debug log
      state = state.copyWith(
        isLoading: false,
        errors: [...state.errors, 'Failed to pick directory: $e'],
      );
    }
  }

  Future<void> _scanDirectory(String path) async {
    try {
      final stats = await _repository.scanDirectory(path, (
        scannedFiles,
        totalDirs,
        scannedDirs,
        imagesFound,
      ) {
        final now = DateTime.now();
        state = state.copyWith(
          scannedFiles: scannedFiles,
          totalDirs: totalDirs,
          scannedDirs: scannedDirs,
          imagesFound: imagesFound,
          elapsedTime: now.difference(_scanStartTime!),
        );
      });

      state = state.copyWith(
        isLoading: false,
        directoryStats: stats,
        errors: _repository.accessErrors,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errors: [...state.errors, e.toString()],
      );
    }
  }

  void cancelScan() {
    _repository.cancelScan();
    state = state.copyWith(isLoading: false);
  }

  void showImagesDialog(BuildContext context, DirectoryStats stats) {
    showDialog(
      context: context,
      builder:
          (context) => ImagesDialog(
            stats: stats,
            relativePath: stats.path,
            dateFormatter: DateFormat('yyyy-MM-dd HH:mm'),
          ),
    );
  }

  void showErrorsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => ErrorsDialog(
            errors: state.errors,
            accessErrors: _repository.accessErrors,
            unscannedDirectories: _repository.unscannedDirectories.toSet(),
            getRelativePath:
                (path) => path.replaceFirst(state.selectedDirectory ?? '', ''),
          ),
    );
  }

  void exitApp() {
    exit(0);
  }
}

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  return DirectoryRepositoryImpl();
});

final photoAnalyzerProvider =
    StateNotifierProvider<PhotoAnalyzerNotifier, PhotoAnalyzerState>((ref) {
      final repository = ref.watch(directoryRepositoryProvider);
      return PhotoAnalyzerNotifier(repository);
    });
