import 'package:alert360_mobile/features/menu/presentation/screens/user_guide1_screen.dart';
import 'package:alert360_mobile/features/menu/presentation/screens/user_guide2_screen.dart';
import 'package:flutter/material.dart';

class UserGuideFlow extends StatefulWidget {
  const UserGuideFlow({super.key});

  @override
  State<UserGuideFlow> createState() => _UserGuideFlowState();
}

class _UserGuideFlowState extends State<UserGuideFlow> {
  int _currentStep = 0;

  void _goToNextStep() {
    setState(() {
      _currentStep = 1;
    });
  }

  void _goToPreviousStep() {
    setState(() {
      _currentStep = 0;
    });
  }

  void _closeGuide() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) {
      return UserGuideScreen(onNext: _goToNextStep, onClose: _closeGuide);
    }

    return UserGuideStep2Screen(
      onBack: _goToPreviousStep,
      onClose: _closeGuide,
    );
  }
}
