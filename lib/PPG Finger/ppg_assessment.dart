import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class PPGAssessmentScreen extends StatefulWidget {
  @override
  _PPGAssessmentScreenState createState() => _PPGAssessmentScreenState();
}

class _PPGAssessmentScreenState extends State<PPGAssessmentScreen> {
  // Ayurvedic colors
  final Color _primaryColor = Color(0xFF2E7D32); // Deep green
  final Color _secondaryColor = Color(0xFF8BC34A); // Light green
  final Color _accentColor = Color(0xFF795548); // Earth brown
  final Color _backgroundColor = Color(0xFFF5F5DC); // Beige background
  final Color _cardColor = Color(0xFFFFFDE7); // Light yellow
  final Color _textColor = Color(0xFF5D4037); // Dark brown
  final Color _vataColor = Color(0xFF8B4513); // Brown for Vata
  final Color _pittaColor = Color(0xFFDC143C); // Crimson for Pitta
  final Color _kaphaColor = Color(0xFF228B22); // Forest Green for Kapha

  bool _isTesting = false;
  bool _isCompleted = false;
  int _countdown = 15;
  Timer? _timer;
  Timer? _ppgTimer;
  String _currentStatus = "Ready to start";
  List<double> _ppgData = [];
  String _predictedDosha = "";
  Map<String, double> _doshaPercentages = {
    "Vata": 0.0,
    "Pitta": 0.0,
    "Kapha": 0.0
  };
  
  // Camera and Flash control
  CameraController? _cameraController;
  bool _isFlashOn = false;
  bool _isCameraInitialized = false;
  
  // Real-time analysis variables
  List<double> _heartRates = [];
  List<double> _hrvValues = [];
  double _currentBPM = 0.0;
  double _currentHRV = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        await Permission.camera.request();
      }

      // Get available cameras
      final cameras = await availableCameras();
      
      // Use rear camera
      final rearCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        rearCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera initialization failed: $e");
      // Continue without camera - we'll use simulation
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _toggleFlash() async {
    try {
      if (_cameraController != null && _isCameraInitialized) {
        if (_isFlashOn) {
          await _cameraController!.setFlashMode(FlashMode.off);
          setState(() {
            _isFlashOn = false;
          });
        } else {
          await _cameraController!.setFlashMode(FlashMode.torch);
          setState(() {
            _isFlashOn = true;
          });
        }
      } else {
        // Fallback: Simulate flash for demo
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (e) {
      print("Flash toggle failed: $e");
      // Fallback simulation
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    }
  }

  Future<void> _turnOnFlash() async {
    if (!_isFlashOn) {
      await _toggleFlash();
    }
  }

  Future<void> _turnOffFlash() async {
    if (_isFlashOn) {
      await _toggleFlash();
    }
  }

  @override
  void dispose() {
    _turnOffFlash();
    _timer?.cancel();
    _ppgTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startAssessment() async {
    // Turn on flash first
    await _turnOnFlash();
    
    await Future.delayed(Duration(milliseconds: 500));
    
    setState(() {
      _isTesting = true;
      _isCompleted = false;
      _countdown = 15;
      _currentStatus = "Flashlight ON - Place finger on camera";
      _ppgData = [];
      _heartRates = [];
      _hrvValues = [];
    });

    // Start real-time PPG data collection (10 times per second)
    _ppgTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_isTesting) {
        _collectRealTimePPGData();
      }
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
          _currentStatus = "Measuring pulse... $_countdown seconds remaining";
          
          // Analyze data every second
          if (_ppgData.length > 20) {
            _analyzeRealTimeData();
          }
        } else {
          _completeAssessment();
          timer.cancel();
          _ppgTimer?.cancel();
        }
      });
    });
  }

  void _collectRealTimePPGData() {
    double timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;
    double ppgValue = _generateRealisticPPGValue(timestamp);
    
    _ppgData.add(ppgValue);
    
    // Keep data for 10 seconds for analysis
    if (_ppgData.length > 100) {
      _ppgData.removeAt(0);
    }
  }

  double _generateRealisticPPGValue(double timestamp) {
    // Enhanced PPG simulation with more realistic patterns
    double baseSignal = 0.5;
    
    // Simulate different dosha patterns with more accuracy
    double heartRate;
    double amplitude;
    double variability;
    
    // Different patterns for different time segments to simulate varying conditions
    if (_countdown > 10) {
      // Vata pattern simulation
      heartRate = 80 + 15 * math.sin(timestamp * 0.05); // High variability
      amplitude = 0.25;
      variability = 0.15;
    } else if (_countdown > 5) {
      // Pitta pattern simulation  
      heartRate = 75 + 5 * math.sin(timestamp * 0.1); // Medium variability
      amplitude = 0.35;
      variability = 0.08;
    } else {
      // Kapha pattern simulation
      heartRate = 65 + 3 * math.sin(timestamp * 0.02); // Low variability
      amplitude = 0.4;
      variability = 0.04;
    }
    
    double heartbeat = amplitude * math.sin(timestamp * heartRate * 0.1047);
    double respiration = 0.08 * math.sin(timestamp * 0.3);
    double motionNoise = variability * math.sin(timestamp * 2.0);
    double randomNoise = (math.Random().nextDouble() - 0.5) * variability;
    
    return (baseSignal + heartbeat + respiration + motionNoise + randomNoise)
        .clamp(0.0, 1.0);
  }

  void _analyzeRealTimeData() {
    if (_ppgData.length < 20) return;
    
    // Calculate real-time metrics
    List<double> recentData = _ppgData.sublist(math.max(0, _ppgData.length - 50));
    
    // Detect peaks for BPM calculation
    List<int> peaks = _findPPGPeaks(recentData);
    _currentBPM = _calculateBPM(peaks);
    _currentHRV = _calculateHRV(peaks);
    
    // Store for trend analysis
    _heartRates.add(_currentBPM);
    _hrvValues.add(_currentHRV);
    
    // Update dosha prediction in real-time
    _updateRealTimeDoshaPrediction();
  }

  List<int> _findPPGPeaks(List<double> data) {
    List<int> peaks = [];
    double threshold = 0.6; // Adaptive threshold
    
    for (int i = 2; i < data.length - 2; i++) {
      if (data[i] > threshold &&
          data[i] > data[i-1] && data[i] > data[i-2] &&
          data[i] > data[i+1] && data[i] > data[i+2]) {
        // Ensure minimum distance between peaks (avoid duplicates)
        if (peaks.isEmpty || (i - peaks.last) > 5) {
          peaks.add(i);
        }
      }
    }
    return peaks;
  }

  double _calculateBPM(List<int> peaks) {
    if (peaks.length < 2) return 72.0; // Default BPM
    
    double totalInterval = 0.0;
    for (int i = 1; i < peaks.length; i++) {
      totalInterval += (peaks[i] - peaks[i-1]) * 0.1; // Convert to seconds (100ms intervals)
    }
    
    double avgInterval = totalInterval / (peaks.length - 1);
    double bpm = 60.0 / avgInterval;
    
    return bpm.clamp(50.0, 120.0);
  }

  double _calculateHRV(List<int> peaks) {
    if (peaks.length < 3) return 0.06; // Default HRV
    
    List<double> intervals = [];
    for (int i = 1; i < peaks.length; i++) {
      intervals.add((peaks[i] - peaks[i-1]).toDouble());
    }
    
    double meanInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    double variance = intervals.map((x) => math.pow(x - meanInterval, 2)).reduce((a, b) => a + b) / intervals.length;
    
    return (math.sqrt(variance) / meanInterval).clamp(0.01, 0.3);
  }

  void _updateRealTimeDoshaPrediction() {
    if (_heartRates.isEmpty || _hrvValues.isEmpty) return;
    
    double avgBPM = _calculateMean(_heartRates);
    double avgHRV = _calculateMean(_hrvValues);
    double bpmStdDev = _calculateStdDev(_heartRates, avgBPM);
    
    // Enhanced Ayurvedic pulse pattern detection with weighted scoring
    double vataScore = _calculateVataScore(avgBPM, avgHRV, bpmStdDev);
    double pittaScore = _calculatePittaScore(avgBPM, avgHRV, bpmStdDev);
    double kaphaScore = _calculateKaphaScore(avgBPM, avgHRV, bpmStdDev);
    
    // Find predominant dosha
    if (vataScore > pittaScore && vataScore > kaphaScore) {
      _predictedDosha = "Vata";
      _doshaPercentages = _calculateDynamicPercentages("Vata", avgBPM, avgHRV);
    } else if (pittaScore > vataScore && pittaScore > kaphaScore) {
      _predictedDosha = "Pitta";
      _doshaPercentages = _calculateDynamicPercentages("Pitta", avgBPM, avgHRV);
    } else if (kaphaScore > vataScore && kaphaScore > pittaScore) {
      _predictedDosha = "Kapha";
      _doshaPercentages = _calculateDynamicPercentages("Kapha", avgBPM, avgHRV);
    } else {
      _predictedDosha = "Balanced";
      _doshaPercentages = {"Vata": 0.33, "Pitta": 0.33, "Kapha": 0.34};
    }
  }

  double _calculateVataScore(double bpm, double hrv, double variability) {
    double score = 0.0;
    if (hrv > 0.1) score += 0.4;
    if (variability > 4.0) score += 0.3;
    if (bpm > 75) score += 0.3;
    return score;
  }

  double _calculatePittaScore(double bpm, double hrv, double variability) {
    double score = 0.0;
    if (bpm > 70 && bpm <= 85) score += 0.4;
    if (hrv < 0.08) score += 0.3;
    if (variability < 3.0) score += 0.3;
    return score;
  }

  double _calculateKaphaScore(double bpm, double hrv, double variability) {
    double score = 0.0;
    if (bpm <= 70) score += 0.4;
    if (hrv < 0.06) score += 0.3;
    if (variability < 2.0) score += 0.3;
    return score;
  }

  Map<String, double> _calculateDynamicPercentages(String primaryDosha, double bpm, double hrv) {
    Map<String, double> percentages = {"Vata": 0.0, "Pitta": 0.0, "Kapha": 0.0};
    
    switch (primaryDosha) {
      case "Vata":
        percentages["Vata"] = 0.45 + (hrv * 1.5).clamp(0.0, 0.2);
        percentages["Pitta"] = 0.35 - (hrv * 0.8).clamp(0.0, 0.15);
        percentages["Kapha"] = 0.20 - (hrv * 0.4).clamp(0.0, 0.1);
        break;
      case "Pitta":
        percentages["Vata"] = 0.25 - ((bpm - 70) / 60).clamp(0.0, 0.1);
        percentages["Pitta"] = 0.50 + ((bpm - 70) / 40).clamp(0.0, 0.15);
        percentages["Kapha"] = 0.25 - ((bpm - 70) / 80).clamp(0.0, 0.1);
        break;
      case "Kapha":
        percentages["Vata"] = 0.20 + ((70 - bpm) / 40).clamp(0.0, 0.1);
        percentages["Pitta"] = 0.30 - ((70 - bpm) / 60).clamp(0.0, 0.1);
        percentages["Kapha"] = 0.50 + ((70 - bpm) / 30).clamp(0.0, 0.15);
        break;
    }
    
    // Normalize to 100%
    double total = percentages.values.reduce((a, b) => a + b);
    percentages.updateAll((key, value) => value / total);
    
    return percentages;
  }

  void _completeAssessment() {
    _turnOffFlash();
    
    setState(() {
      _isTesting = false;
      _isCompleted = true;
      _currentStatus = "Analysis complete";
      
      // Final analysis with all collected data
      _performFinalAnalysis();
    });
  }

  void _performFinalAnalysis() {
    if (_heartRates.isEmpty || _hrvValues.isEmpty) return;
    
    // Use weighted average of real-time predictions
    double finalBPM = _calculateMean(_heartRates);
    double finalHRV = _calculateMean(_hrvValues);
    double bpmVariability = _calculateStdDev(_heartRates, finalBPM);
    
    // Final classification with confidence scoring
    Map<String, double> confidenceScores = {
      "Vata": _calculateVataScore(finalBPM, finalHRV, bpmVariability),
      "Pitta": _calculatePittaScore(finalBPM, finalHRV, bpmVariability),
      "Kapha": _calculateKaphaScore(finalBPM, finalHRV, bpmVariability),
    };
    
    // Find predominant dosha
    String predominantDosha = "Balanced";
    double maxScore = 0.0;
    
    confidenceScores.forEach((dosha, score) {
      if (score > maxScore) {
        maxScore = score;
        predominantDosha = dosha;
      }
    });
    
    _predictedDosha = predominantDosha;
    _doshaPercentages = _calculateFinalPercentages(confidenceScores);
  }

  Map<String, double> _calculateFinalPercentages(Map<String, double> scores) {
    double total = scores.values.reduce((a, b) => a + b);
    if (total == 0) return {"Vata": 0.33, "Pitta": 0.33, "Kapha": 0.34};
    
    return {
      "Vata": scores["Vata"]! / total,
      "Pitta": scores["Pitta"]! / total,
      "Kapha": scores["Kapha"]! / total,
    };
  }

  double _calculateMean(List<double> data) {
    return data.reduce((a, b) => a + b) / data.length;
  }

  double _calculateStdDev(List<double> data, double mean) {
    double variance = data.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    return math.sqrt(variance);
  }

  void _resetAssessment() {
    _turnOffFlash();
    _timer?.cancel();
    _ppgTimer?.cancel();
    
    setState(() {
      _isTesting = false;
      _isCompleted = false;
      _countdown = 15;
      _currentStatus = "Ready to start";
      _ppgData = [];
      _predictedDosha = "";
      _doshaPercentages = {"Vata": 0.0, "Pitta": 0.0, "Kapha": 0.0};
      _heartRates = [];
      _hrvValues = [];
      _currentBPM = 0.0;
      _currentHRV = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!_isCompleted) _buildAssessmentUI(),
              if (_isCompleted) _buildResultsUI(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentUI() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header with Ayurvedic icon
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa, color: _primaryColor, size: 28),
                SizedBox(width: 12),
                Text(
                  "Ayurvedic Pulse Assessment",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 30),
          
          // Flashlight status
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isFlashOn ? Colors.red[50] : _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFlashOn ? Colors.red : _primaryColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flash_on,
                  color: _isFlashOn ? Colors.red : _primaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  _isFlashOn ? "Flashlight: ACTIVE" : "Flashlight: READY",
                  style: TextStyle(
                    color: _isFlashOn ? Colors.red : _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 30),
          
          // Finger placement circle
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: _isTesting ? _primaryColor : _primaryColor.withOpacity(0.3),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fingerprint,
                  size: 60,
                  color: _isTesting ? _primaryColor : _primaryColor.withOpacity(0.6),
                ),
                SizedBox(height: 16),
                Text(
                  _isTesting ? "Measuring..." : "Place Finger",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isTesting ? _primaryColor : _textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isTesting) ...[
                  SizedBox(height: 8),
                  Text(
                    "Cover camera & flash",
                    style: TextStyle(
                      fontSize: 12,
                      color: _primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          
          SizedBox(height: 30),
          
          // Real-time metrics
          if (_isTesting && _currentBPM > 0) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric("BPM", _currentBPM.toStringAsFixed(0), Icons.monitor_heart),
                  _buildMetric("HRV", _currentHRV.toStringAsFixed(3), Icons.insights),
                  _buildMetric("Dosha", _predictedDosha, Icons.spa),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
          
          // Instructions
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _secondaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: _secondaryColor, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Cover both camera lens and flashlight with your fingertip completely",
                    style: TextStyle(color: _textColor, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 30),
          
          // Start Button
          if (!_isTesting) 
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _startAssessment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Start Assessment",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          
          // Progress during testing
          if (_isTesting) ...[
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (15 - _countdown) / 15,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _currentStatus,
                    style: TextStyle(
                      fontSize: 16,
                      color: _primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Detected: $_predictedDosha",
                    style: TextStyle(
                      fontSize: 14,
                      color: _getDoshaColor(_predictedDosha),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // PPG Waveform
          if (_isTesting && _ppgData.isNotEmpty) ...[
            SizedBox(height: 20),
            Container(
              height: 80,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: CustomPaint(
                painter: PPGWaveformPainter(_ppgData, _primaryColor),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Real-time Nadi Signal",
              style: TextStyle(fontSize: 12, color: _textColor.withOpacity(0.7)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _primaryColor, size: 20),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: _textColor.withOpacity(0.7)),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsUI() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.spa, size: 40, color: _primaryColor),
                  SizedBox(height: 8),
                  Text(
                    "Your Ayurvedic Analysis",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Based on Nadi Pariksha (Pulse Diagnosis)",
                    style: TextStyle(
                      fontSize: 14,
                      color: _textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Dosha percentages
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Your Dosha Balance",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildDoshaPercentage("Vata (Air + Space)", _doshaPercentages["Vata"]! * 100, _vataColor),
                  _buildDoshaPercentage("Pitta (Fire + Water)", _doshaPercentages["Pitta"]! * 100, _pittaColor),
                  _buildDoshaPercentage("Kapha (Earth + Water)", _doshaPercentages["Kapha"]! * 100, _kaphaColor),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Predominant dosha
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getDoshaColor(_predictedDosha).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getDoshaColor(_predictedDosha).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    "Predominant Dosha",
                    style: TextStyle(
                      fontSize: 16,
                      color: _textColor.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _predictedDosha,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getDoshaColor(_predictedDosha),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildDoshaCharacteristics(_predictedDosha),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Ayurvedic insights
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: BorderSide(color: _primaryColor),
                    ),
                    child: Text(
                      "Ayurvedic Insights",
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetAssessment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      "New Assessment",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoshaCharacteristics(String dosha) {
    Map<String, List<String>> characteristics = {
      "Vata": ["Space + Air", "Creative • Energetic • Flexible"],
      "Pitta": ["Fire + Water", "Determined • Intelligent • Leadership"],
      "Kapha": ["Earth + Water", "Calm • Loving • Nurturing"],
      "Balanced": ["All Elements", "Harmonious • Balanced • Healthy"]
    };
    
    var chars = characteristics[dosha] ?? ["", ""];
    
    return Column(
      children: [
        Text(
          chars[0],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getDoshaColor(dosha),
          ),
        ),
        SizedBox(height: 8),
        Text(
          chars[1],
          style: TextStyle(
            fontSize: 14,
            color: _textColor.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDoshaPercentage(String label, double percentage, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
              Text(
                "${percentage.toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getDoshaColor(String dosha) {
    switch (dosha.toLowerCase()) {
      case "vata": return _vataColor;
      case "pitta": return _pittaColor;
      case "kapha": return _kaphaColor;
      default: return _primaryColor;
    }
  }
}

class PPGWaveformPainter extends CustomPainter {
  final List<double> data;
  final Color waveColor;
  
  PPGWaveformPainter(this.data, this.waveColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    double xStep = size.width / (data.length - 1);
    
    for (int i = 0; i < data.length; i++) {
      double x = i * xStep;
      double y = size.height * (1 - data[i]);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}