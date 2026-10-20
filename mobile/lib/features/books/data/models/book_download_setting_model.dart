// lib/features/books/data/models/book_download_setting_model.dart

enum BookDownloadDestination {
  inApp,
  deviceFileManager,
  both;

  String get backendValue {
    switch (this) {
      case BookDownloadDestination.inApp:
        return 'IN_APP';
      case BookDownloadDestination.deviceFileManager:
        return 'DEVICE_FILE_MANAGER';
      case BookDownloadDestination.both:
        return 'BOTH';
    }
  }

  String get label {
    switch (this) {
      case BookDownloadDestination.inApp:
        return 'In-App Downloads (Default)';
      case BookDownloadDestination.deviceFileManager:
        return 'Device File Manager';
      case BookDownloadDestination.both:
        return 'Both (In-App & Device)';
    }
  }

  String get shortLabel {
    switch (this) {
      case BookDownloadDestination.inApp:
        return 'In-App';
      case BookDownloadDestination.deviceFileManager:
        return 'Device File';
      case BookDownloadDestination.both:
        return 'Both';
    }
  }

  String get description {
    switch (this) {
      case BookDownloadDestination.inApp:
        return 'Downloaded books are saved in the application\'s managed local storage. Available for offline reading in the app library.';
      case BookDownloadDestination.deviceFileManager:
        return 'Downloaded books are saved directly to the device\'s user-accessible Downloads folder for external viewing and sharing.';
      case BookDownloadDestination.both:
        return 'Saved in the application\'s managed offline library AND exported to the user\'s device Downloads directory.';
    }
  }

  static BookDownloadDestination fromString(String? value) => fromBackend(value);

  static BookDownloadDestination fromBackend(String? value) {
    switch (value?.toUpperCase()) {
      case 'DEVICE_FILE_MANAGER':
      case 'DEVICEFILEMANAGER':
        return BookDownloadDestination.deviceFileManager;
      case 'BOTH':
        return BookDownloadDestination.both;
      case 'IN_APP':
      case 'INAPP':
      default:
        return BookDownloadDestination.inApp;
    }
  }
}

class BookDownloadSettingModel {
  final String id;
  final BookDownloadDestination destination;
  final String? description;
  final String? updatedById;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookDownloadSettingModel({
    this.id = 'default',
    this.destination = BookDownloadDestination.inApp,
    this.description,
    this.updatedById,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory BookDownloadSettingModel.fromJson(Map<String, dynamic> json) {
    return BookDownloadSettingModel(
      id: json['id'] as String? ?? 'default',
      destination: BookDownloadDestination.fromBackend(json['destination'] as String?),
      description: json['description'] as String?,
      updatedById: json['updatedById'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'destination': destination.backendValue,
        if (description != null) 'description': description,
      };
}
