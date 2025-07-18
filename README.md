# Hello PDF - Complete PDF Management App

A comprehensive Flutter application for PDF management with OCR capabilities, editing features, and password protection.

## Features

### 🔍 OCR Scanner
- **Camera Capture**: Take photos of documents using the device camera
- **Gallery Import**: Select images from the photo gallery
- **Text Extraction**: Advanced OCR using Google ML Kit for text recognition
- **Text Editing**: Edit extracted text before converting to PDF
- **PDF Generation**: Convert scanned text to professional PDF documents

### 📁 PDF Viewer & Management
- **My PDFs**: View all PDFs saved in the app
- **Search Functionality**: Find PDFs quickly with search
- **PDF Viewer**: Built-in PDF viewer with page navigation
- **File Management**: Organize and manage your PDF library
- **Move to Downloads**: Transfer PDFs to device download folder

### ✂️ PDF Editor
- **Page Management**: Remove unwanted pages from PDFs
- **Page Extraction**: Create new PDFs from selected pages
- **PDF Merging**: Combine multiple PDFs into one document
- **Visual Page Selection**: Easy page selection with grid view

### 📝 Text to PDF
- **Simple Text**: Convert plain text to PDF documents
- **Formatted Documents**: Create professional PDFs with titles and authors
- **Table Generator**: Create PDFs with tables from CSV data
- **Customization**: Adjust font size, page format, and document settings

### 🔐 Password Manager
- **Add Protection**: Secure PDFs with password protection
- **Remove Protection**: Remove passwords from protected PDFs
- **Bulk Operations**: Protect or unprotect multiple PDFs at once
- **Security Status**: View protection status of all documents

## Architecture

### Project Structure
```
lib/
├── app.dart                 # Main app configuration
├── main.dart               # App entry point
├── features/               # Feature-based modules
│   ├── home/              # Home screen
│   ├── ocr_scanner/       # OCR and scanning
│   ├── pdf_viewer/        # PDF viewing and management
│   ├── pdf_editor/        # PDF editing tools
│   ├── text_to_pdf/       # Text to PDF conversion
│   └── password_manager/  # Password protection
├── models/                # Data models
├── providers/             # Riverpod state management
├── services/              # Business logic services
└── utils/                 # Utility functions
```

### State Management
- **Riverpod**: Used for state management and dependency injection
- **Provider Scope**: App-wide state management for PDF documents
- **File Management**: Centralized file operations and metadata handling

### Services
- **FileService**: Handles file operations and storage management
- **OcrService**: Manages camera capture and text recognition
- **PdfEditingService**: PDF manipulation and editing operations
- **TextToPdfService**: Text to PDF conversion with formatting options

## Dependencies

### Core Dependencies
- `flutter_riverpod`: State management
- `path_provider`: File system access
- `permission_handler`: Runtime permissions

### PDF & Document Processing
- `pdf`: PDF generation and manipulation
- `syncfusion_flutter_pdf`: Advanced PDF operations
- `syncfusion_flutter_pdfviewer`: PDF viewing capabilities
- `flutter_pdfview`: Alternative PDF viewer

### Camera & OCR
- `image_picker`: Camera and gallery access
- `camera`: Camera functionality
- `google_mlkit_text_recognition`: OCR text extraction

### File Management
- `file_picker`: File selection and import
- `flutter_speed_dial`: Floating action buttons
- `flutter_colorpicker`: Color selection utilities

## Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Android Configuration
The app requires the following permissions (already configured):
- Camera access for document scanning
- Storage access for file management
- Internet access for ML Kit operations

### 3. Run the App
```bash
flutter run
```

## Usage Guide

### Getting Started
1. Launch the app to see the main dashboard
2. Use the feature cards to navigate to different functionalities
3. Grant necessary permissions when prompted

### Scanning Documents
1. Tap "Scan Document" from the home screen
2. Choose "Camera" or "Gallery" to capture/select an image
3. Tap "Extract Text" to perform OCR
4. Edit the extracted text if needed
5. Add a title and save as PDF

### Managing PDFs
1. Tap "My PDFs" to view your document library
2. Use the search bar to find specific documents
3. Tap on any PDF to view it
4. Use the menu button for additional options (share, delete, move)

### Editing PDFs
1. Go to "Edit PDF" and select a document
2. Choose from page management, security, or PDF operations
3. Select pages using the visual grid selector
4. Apply operations like remove pages or extract pages

### Converting Text to PDF
1. Use "Text to PDF" for document creation
2. Choose between Simple, Formatted, or Table modes
3. Enter your content and customize settings
4. Generate professional PDF documents

### Password Protection
1. Access "Password Manager" to secure your PDFs
2. Add passwords to individual documents
3. Use bulk operations for multiple files
4. Monitor protection status of your library

## File Storage

### App Data Directory
- All PDFs are initially stored in the app's private directory
- Metadata is maintained in JSON format for quick access
- Files can be moved to the public Downloads folder

### Download Integration
- Processed PDFs can be moved to the device's Downloads folder
- User chooses whether to keep files in app or move to Downloads
- Seamless integration with device file managers

## Advanced Features

### OCR Accuracy
- Uses Google ML Kit for high-accuracy text recognition
- Supports multiple languages and text orientations
- Handles various document types and image qualities

### PDF Generation
- Professional document formatting
- Customizable page layouts and font sizes
- Support for headers, footers, and page numbering

### Security Features
- Password protection using industry-standard encryption
- Secure file storage in app sandbox
- Permission-based access control

## Technical Notes

### Performance
- Efficient file management with metadata caching
- Background processing for large operations
- Optimized PDF rendering and viewing

### Compatibility
- Supports Android API levels for camera and file access
- Cross-platform Flutter implementation
- Adaptive UI for different screen sizes

### Error Handling
- Comprehensive error handling throughout the app
- User-friendly error messages and recovery options
- Graceful handling of permission denials

## Development

### Building for Release
```bash
flutter build apk --release
```

### Adding Features
The modular architecture makes it easy to add new features:
1. Create a new feature directory under `lib/features/`
2. Add corresponding services in `lib/services/`
3. Update providers in `lib/providers/`
4. Add navigation from the home screen

### Contributing
This project follows clean architecture principles with clear separation of concerns. Each feature is self-contained and communicates through well-defined interfaces.

## Troubleshooting

### Common Issues
1. **Permission Errors**: Ensure all required permissions are granted
2. **OCR Not Working**: Check camera permissions and internet connectivity
3. **PDF Not Saving**: Verify storage permissions and available space
4. **App Crashes**: Check device compatibility and Flutter version

### Support
For issues and feature requests, please refer to the project documentation or create an issue in the repository.

---

**Hello PDF** - Your complete PDF management solution! 📄✨
