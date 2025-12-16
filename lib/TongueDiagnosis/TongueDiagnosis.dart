import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_app/FLASK%20API/tongue_api_service.dart';
import 'dart:io';


class TongueDiagnosisPage extends StatefulWidget {
  @override
  _TongueDiagnosisPageState createState() => _TongueDiagnosisPageState();
}

class _TongueDiagnosisPageState extends State<TongueDiagnosisPage> {
  final TongueApiService _apiService = TongueApiService();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  bool _isAnalyzing = false;
  String _diagnosisResult = '';
  String _confidence = '';
  String _additionalInfo = '';
  bool _isServerConnected = false;
  bool _isCheckingConnection = false;

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
  }

  Future<void> _checkServerConnection() async {
    setState(() {
      _isCheckingConnection = true;
    });
    
    final isConnected = await _apiService.checkServerConnection();
    
    setState(() {
      _isServerConnected = isConnected;
      _isCheckingConnection = false;
    });
    
    if (!isConnected) {
      _showConnectionError('Cannot connect to server at ${TongueApiService.baseUrl}. Please ensure: \n\n1. Flask server is running\n2. IP address is correct\n3. Both devices are on same WiFi\n4. Firewall is not blocking connection');
    }
  }

  Future<void> _captureImage() async {
    if (!_isServerConnected) {
      _showConnectionError('Server not connected. Please check connection and try again.');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _analyzeImage(File(image.path));
      }
    } catch (e) {
      _showErrorDialog('Camera Error', 'Could not capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (!_isServerConnected) {
      _showConnectionError('Server not connected. Please check connection and try again.');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _analyzeImage(File(image.path));
      }
    } catch (e) {
      _showErrorDialog('Gallery Error', 'Could not pick image: $e');
    }
  }

  void _showConnectionError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connection Issue'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkServerConnection();
            },
            child: Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeImage(File image) async {
    setState(() {
      _isAnalyzing = true;
      _selectedImage = image;
      _diagnosisResult = 'Sending image to AI model...';
      _confidence = '';
      _additionalInfo = '';
    });

    final result = await _apiService.analyzeTongueImage(image);
    
    result.fold(
      (error) {
        setState(() {
          _diagnosisResult = 'Error: $error';
          _isAnalyzing = false;
        });
        
        _showErrorDialog('Analysis Failed', 'Could not analyze image: $error');
      },
      (data) {
        // Parse response - adjust based on your Flask API response structure
        final diagnosis = data['diagnosis'] ?? data['prediction'] ?? data['result'] ?? 'Analysis complete';
        final confidence = data['confidence'] ?? data['score'] ?? data['probability'];
        final additionalInfo = data['additional_info'] ?? data['recommendations'] ?? data['message'] ?? '';
        
        setState(() {
          _diagnosisResult = diagnosis.toString();
          _confidence = confidence != null 
              ? 'Confidence: ${(confidence is double ? confidence * 100 : double.tryParse(confidence.toString()) ?? 0).toStringAsFixed(1)}%'
              : '';
          _additionalInfo = additionalInfo is String ? additionalInfo : additionalInfo.toString();
          _isAnalyzing = false;
        });
      },
    );
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _diagnosisResult = '';
      _confidence = '';
      _additionalInfo = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/yy.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
              
              // Content
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Section
                      _buildHeaderSection(),
                      SizedBox(height: 20),
                      
                      // Server Status
                      _buildServerStatus(),
                      SizedBox(height: 20),
                      
                      // Main Content Section
                      _buildMainContentSection(),
                      SizedBox(height: 20),
                      
                      // Diagnosis Result
                      if (_diagnosisResult.isNotEmpty)
                        _buildDiagnosisResultSection(),
                      
                      // Features Section
                      _buildFeaturesSection(),
                      SizedBox(height: 30),
                      
                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Text(
          'Tongue TCM Diagnosis AI',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Container(
          height: 3,
          width: 60,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildServerStatus() {
    Color statusColor = _isCheckingConnection 
        ? Colors.blue
        : _isServerConnected 
            ? Colors.green 
            : Colors.red;
    
    IconData statusIcon = _isCheckingConnection 
        ? Icons.refresh
        : _isServerConnected 
            ? Icons.check_circle 
            : Icons.error;
    
    String statusText = _isCheckingConnection 
        ? 'Checking Connection...'
        : _isServerConnected 
            ? 'Server Connected' 
            : 'Server Disconnected';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isCheckingConnection)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(statusIcon, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '(${TongueApiService.baseUrl})',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          if (!_isCheckingConnection && !_isServerConnected) ...[
            SizedBox(width: 8),
            GestureDetector(
              onTap: _checkServerConnection,
              child: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContentSection() {
    return Column(
      children: [
        Text(
          'Discover Your Health',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Through Traditional Chinese Medicine',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30),
        
        // Image Preview
        _buildImagePreview(),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/yy1.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            if (_isAnalyzing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Analyzing...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          _selectedImage != null ? 'Image Ready for Analysis' : 'Your Tongue Image',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_selectedImage != null) ...[
          SizedBox(height: 8),
          Text(
            'Tap buttons below to analyze',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiagnosisResultSection() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'TCM Diagnosis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            _diagnosisResult,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_confidence.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              _confidence,
              style: TextStyle(
                color: Colors.yellow[300],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_additionalInfo.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _additionalInfo,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      children: [
        _buildFeatureItem(
          icon: Icons.photo_camera,
          title: 'Take a Photo',
          subtitle: 'Capture your tongue image with camera',
        ),
        SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.psychology,
          title: 'AI Analysis',
          subtitle: 'Flask deep learning model analysis',
        ),
        SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.health_and_safety,
          title: 'TCM Insights',
          subtitle: 'Traditional Chinese Medicine diagnosis',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            icon,
            color: Colors.red[600],
            size: 22,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Camera Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isAnalyzing ? null : _captureImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isServerConnected ? Colors.red[700] : Colors.grey,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: _isAnalyzing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Analyzing...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt),
                      SizedBox(width: 8),
                      Text(
                        'Take Tongue Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 12),
        
        // Gallery Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isAnalyzing ? null : _pickImageFromGallery,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white, width: 2),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library),
                SizedBox(width: 8),
                Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Reset Button
        if (_diagnosisResult.isNotEmpty && !_isAnalyzing) ...[
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _resetAnalysis,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text(
                    'Analyze Another Image',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}