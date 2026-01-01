import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/ui/landing_page/landing_screen.dart';
import 'package:konek2move/ui/progress_page/progress_tracker_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/widgets/custom_dialog.dart';
import 'package:konek2move/widgets/custom_dropdown.dart';
import 'package:konek2move/widgets/custom_input_fields.dart';


class RegisterScreen extends StatefulWidget {
  final String email;
  const RegisterScreen({super.key, required this.email});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Personal Info
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _mnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  // Contact Info
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  // final TextEditingController _regionController = TextEditingController();

  // Vehicle Info
  File? _drivingLicenseFront;
  File? _drivingLicenseBack;
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();

  // Set-up Password
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool isMobileValid = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? selectedSuffix;
  String? selectedGender;
  String? selectedVehicle;
  // String? selectedRegion;

  int _currentStep = 0; // 0 = personal, 1 = contact, 2 = vehicle, 3 = password
  final PageController _pageController = PageController();

  List<String> suffixOptions = [];
  List<String> genderOptions = [];
  List<String> vehicleOptions = [];
  // List<String> regionOptions = [];

  Future<void> _pickImage(
      Function(File) onImagePicked,
      BuildContext context,
      ) async {
    final ImagePicker picker = ImagePicker();
    final bottom = MediaQuery.of(context).padding.bottom;

    await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- DRAG HANDLE (Same as CustomDropdownField) ---
              Container(
                height: 5,
                width: 50,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // --- TITLE ---
              const Text(
                "Select Image",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              // --- SUBTITLE ---
              Text(
                "Choose where to get your image from",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              // --- GRID OPTIONS (Camera / Gallery) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.blue[50],
                          child: Icon(Icons.camera_alt_rounded,color: AppColors.primary)
                        ),
                        const SizedBox(height: 8),
                        const Text("Camera", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.green[50],
                          child: Icon(Icons.photo_library_rounded,color: AppColors.primary,)
                        ),
                        const SizedBox(height: 8),
                        const Text("Gallery", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Divider(),

              // --- CANCEL BUTTON ---
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    ).then((source) async {
      if (source != null) {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          onImagePicked(File(pickedFile.path));
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fnameController.addListener(_onFieldChanged);
    _mnameController.addListener(_onFieldChanged);
    _lnameController.addListener(_onFieldChanged);
    _genderController.addListener(_onFieldChanged);
    _mobileController.addListener(_onFieldChanged);
    _vehicleController.addListener(_onFieldChanged);
    _licenseController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _emailController.text = widget.email;
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
    _loadDropdownOptions();
  }

  bool _isFormValid() {
    return isMobileValid &&
        _fnameController.text.isNotEmpty &&
        _lnameController.text.isNotEmpty &&
        selectedGender != null &&
        selectedGender!.isNotEmpty &&
        _vehicleController.text.isNotEmpty &&
        _licenseController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text &&
        _drivingLicenseFront != null &&
        _drivingLicenseBack != null;
  }

  bool _isPersonalInfoValid() {
    return _fnameController.text.isNotEmpty &&
        _lnameController.text.isNotEmpty &&
        selectedGender != null &&
        selectedGender!.isNotEmpty;
  }

  bool _isContactInfoValid() {
    return _mobileController.text.trim().length == 11 &&
        _mobileController.text.trim().startsWith('09') &&
        _emailController.text.endsWith('@gmail.com') &&
        _addressController.text.isNotEmpty;
  }

  bool _isVehicleInfoValid() {
    return _drivingLicenseFront != null &&
        _drivingLicenseBack != null &&
        _vehicleController.text.isNotEmpty &&
        _licenseController.text.isNotEmpty;
  }

  void _onFieldChanged() {
    final mobileValid =
        _mobileController.text.length == 11 &&
            _mobileController.text.startsWith('09');
    setState(() {
      isMobileValid = mobileValid;
    });
  }

  void _onRegister() async {
    if (!_isFormValid()) return;

    // === Debug Output ===
    debugPrint('''
--- Registration Data ---
First Name: ${_fnameController.text.trim()}
Middle Name: ${_mnameController.text.trim()}
Last Name: ${_lnameController.text.trim()}
Suffix: $selectedSuffix
Gender: $selectedGender
Email: ${_emailController.text.trim()}
Phone: ${_mobileController.text.trim()}
Address: ${_addressController.text.trim()}
Password: ${_passwordController.text}
Vehicle Type: ${_vehicleController.text.trim()}
License Number: ${_licenseController.text.trim()}
License Front Path: ${_drivingLicenseFront?.path}
License Back Path: ${_drivingLicenseBack?.path}
-------------------------
  ''');

    // === Validate License Files ===
    if (_drivingLicenseFront == null || _drivingLicenseBack == null) {
      _showDialogMessage(
        message: "Please upload both front and back images of your license.",
        isError: true,
      );
      return;
    }

    // === Show Loading Dialog ===
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final api = ApiServices();
      final response = await api.signup(
        firstName: _fnameController.text.trim(),
        middleName: _mnameController.text.trim().isEmpty
            ? null
            : _mnameController.text.trim(),
        lastName: _lnameController.text.trim(),
        suffix: selectedSuffix,
        gender: selectedGender!,
        email: _emailController.text.trim(),
        phone: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        password: _passwordController.text,
        vehicleType: _vehicleController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        licenseFront: _drivingLicenseFront!,
        licenseBack: _drivingLicenseBack!,
      );

      // === Close Loading Only if Mounted ===
      if (mounted) Navigator.pop(context);

      if (response.retCode == '200') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProgressTrackerScreen()),
        );
      } else {
        _showDialogMessage(message: response.message!, isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      _showDialogMessage(
        message: 'Registration failed: $e',
        isError: true,
      );
    }
  }


  /// --- CUSTOM DIALOG HANDLING ---
  void _showDialogMessage({
    required String message,
    bool isError = false,
  }) {
    final color = isError ? Colors.redAccent : Colors.green;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    showCustomDialog(
      context: context,
      title: isError ? "Error" : "Success",
      message: message,
      icon: icon,
      color: color,
      buttonText: "Okay!",
      onButtonPressed: () async {
        Navigator.pop(context); // close dialog
      },
    );
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _mnameController.dispose();
    _lnameController.dispose();
    _suffixController.dispose();
    _genderController.dispose();
    _mobileController.dispose();
    _vehicleController.dispose();
    _licenseController.dispose();
    _addressController.dispose();
    // _regionController.dispose();
    _emailController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownOptions() async {
    try {
      final Map<String, List<String>> dropdowns = await ApiServices()
          .fetchDropdownOptions();

      // Capitalize first letter of each vehicle option
      List<String> suffix = (dropdowns['suffix'] ?? []).toList();
      List<String> gender = (dropdowns['gender'] ?? []).toList();
      List<String> vehicles = (dropdowns['vehicle_type'] ?? []).toList();

      setState(() {
        suffixOptions = suffix;
        genderOptions = gender;
        vehicleOptions = vehicles;
      });
    } catch (e) {
      debugPrint("Error loading dropdowns: $e");
    }
  }

  // ------------------------------------------------------------------
  // NEW BUILD: MATCHES TERMS & CONDITION LAYOUT
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      appBar:AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Registration",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),

      body: Column(
        children: [
          /// Progress steps (fixed height)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: _buildProgressSteps(),
          ),

          /// Dynamic pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPersonalInfoStep(),
                _buildContactInfoStep(),
                _buildVehicleInfoStep(),
                _buildSetupPasswordStep(),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomAction(context),
    );
  }

  Widget _buildProgressSteps() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _modernStep(0, "Personal Info"),
          _stepConnector(0),
          _modernStep(1, "Contact Details"),
          _stepConnector(1),
          _modernStep(2, "Vehicle Details"),
          _stepConnector(2),
          _modernStep(3, "Set-up Password"),
        ],
      ),
    );
  }

  Widget _modernStep(int index, String label) {
    bool isActive = _currentStep >= index;
    bool isCurrent = _currentStep == index;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 34 : 30,
          height: isCurrent ? 34 : 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            boxShadow: isActive
                ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : [],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: isCurrent ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
              child: Text("${index + 1}"),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.primary : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  /// Horizontal line between circles
  Widget _stepConnector(int index) {
    bool isActive = _currentStep > index;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // GLOBAL BOTTOM ACTION BAR (BACK / NEXT / FINISH)
  // ------------------------------------------------------------------
  Widget _buildBottomAction(BuildContext context) {
    final bool isLastStep = _currentStep == 3;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // Detect 3-button navigation (no safe inset)
    final bool isThreeButtonNav = safeBottom == 0;

    bool canProceed;
    switch (_currentStep) {
      case 0:
        canProceed = _isPersonalInfoValid();
        break;
      case 1:
        canProceed = _isContactInfoValid();
        break;
      case 2:
        canProceed = _isVehicleInfoValid();
        break;
      case 3:
        canProceed = _isFormValid();
        break;
      default:
        canProceed = false;
    }

    return SafeArea(
      bottom: false, // ← REQUIRED so 3-button nav does NOT cover the UI
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          isThreeButtonNav ? 16 : safeBottom + 14,
        ),
        color: Colors.white,
        child: Row(
          children: [

            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep--);
                    _pageController.animateToPage(
                      _currentStep,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text("Back"),
                ),
              ),

            if (_currentStep > 0) const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton(
                onPressed: canProceed
                    ? () {
                  if (isLastStep) {
                    _onRegister();
                  } else {
                    setState(() => _currentStep++);
                    _pageController.animateToPage(
                      _currentStep,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(isLastStep ? "Submit" : "Next"),
              ),
            ),
          ],
        ),
      )

    );
  }

  // ---------------------------------------------------------
  // STEP 1 — PERSONAL INFO
  // ---------------------------------------------------------
  Widget _buildPersonalInfoStep() {
    return _stepWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            title: "Create an account to start delivering",
            image: "assets/images/register.png",
          ),
          const SizedBox(height: 16),

          CustomInputField(
            required: true,
            label: "First Name",
            hint: "First Name",
            controller: _fnameController,
          ),

          const SizedBox(height: 16),

          CustomInputField(
            label: "Middle Name",
            hint: "Middle Name (Optional)",
            controller: _mnameController,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomInputField(
                  required: true,
                  label: "Last Name",
                  hint: "Last Name",
                  controller: _lnameController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomDropdownField(
                  label: "Suffix",
                  hint: "Suffix",
                  options: suffixOptions,
                  value: selectedSuffix,
                  onChanged: (val) {
                    setState(() {
                      selectedSuffix = val;
                      _suffixController.text = val ?? "";
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          CustomDropdownField(
            label: "Gender",
            hint: "Select Gender",
            options: genderOptions,
            value: selectedGender,
            required: true,
            onChanged: (val) {
              setState(() {
                selectedGender = val;
                _genderController.text = val ?? "";
              });
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // STEP 2 — CONTACT INFO
  // ---------------------------------------------------------
  Widget _buildContactInfoStep() {
    return _stepWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            title: "We’ll need your contact details",
            image: "assets/images/contact.png",
          ),
          const SizedBox(height: 16),

          CustomInputField(
            required: true,
            label: "Mobile Number",
            hint: "09123456789",
            controller: _mobileController,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            maxLength: 11,
          ),

          CustomInputField(
            required: true,
            label: "Email Address",
            hint: "name@example.com",
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          CustomInputField(
            required: true,
            label: "Complete Address",
            hint: "House No., Street, Barangay, City",
            controller: _addressController,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // STEP 3 — VEHICLE INFO
  // ---------------------------------------------------------
  Widget _buildVehicleInfoStep() {
    return _stepWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            title: "Please provide your vehicle details",
            image: "assets/images/vehicle.png",
          ),
          const SizedBox(height: 16),

          _buildDocumentUploadItem(
            title: "Driving License (Front)",
            subtitle:
            "Upload a clear photo of the front side of your vehicle’s license plate. Ensure the plate number is fully visible and legible, with no obstructions or glare.",
            imageFile: _drivingLicenseFront,
            onUploadTap: () {
              _pickImage((file) {
                setState(() => _drivingLicenseFront = file);
              }, context);
            },
          ),

          const SizedBox(height: 16),

          _buildDocumentUploadItem(
            title: "Driving License (Back)",
            subtitle:
            "Upload a clear photo of the back side of your vehicle’s license plate. Make sure the plate number is fully visible and readable, with no obstructions or glare.",
            imageFile: _drivingLicenseBack,
            onUploadTap: () {
              _pickImage((file) {
                setState(() => _drivingLicenseBack = file);
              }, context);
            },
          ),

          const SizedBox(height: 16),

          CustomInputField(
            required: true,
            label: "Driver’s License Number",
            hint: "License Number",
            controller: _licenseController,
            maxLength: 12,
          ),

          const SizedBox(height: 16),

          CustomDropdownField(
            label: "Vehicle Type",
            hint: "Select Vehicle Type",
            options: vehicleOptions,
            value: selectedVehicle,
            required: true,
            onChanged: (val) {
              setState(() {
                selectedVehicle = val;
                _vehicleController.text = val ?? "";
              });
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // STEP 4 — SET UP PASSWORD
  // ---------------------------------------------------------
  Widget _buildSetupPasswordStep() {
    return _stepWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            title: "We’ll need to set up your password",
            image: "assets/images/password.png",
          ),
          const SizedBox(height: 16),

        CustomInputField(
          required: true,
          label: "Password",
          hint: "Enter your password",
          controller: _passwordController,
          obscure: !_isPasswordVisible,
          suffixIcon: _isPasswordVisible        // 👁 show
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,  // 👁‍🗨 hide
          onSuffixTap: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),

        const SizedBox(height: 16),

      CustomInputField(
        required: true,
        label: "Confirm Password",
        hint: "Re-enter your password",
        controller: _confirmPasswordController,
        obscure: !_isConfirmPasswordVisible,
        suffixIcon: _isConfirmPasswordVisible
            ? Icons.visibility_rounded       // 👁 visible
            : Icons.visibility_off_rounded, // 👁‍🗨 hidden
        onSuffixTap: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
        ),
      ),
      ],
      ),
    );
  }

  // ---------------------------------------------------------
  // REUSABLE WIDGETS
  // ---------------------------------------------------------
  Widget _buildDocumentUploadItem({
    required String title,
    required String subtitle,
    required File? imageFile,
    required VoidCallback onUploadTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(text: const TextSpan(text: "")),
                RichText(
                  text: TextSpan(
                    text: title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    children: const [
                      TextSpan(
                        text: " *",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onUploadTap,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: imageFile == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 30, color: Colors.black87),
                  const SizedBox(height: 8),
                  Text(
                    "Upload Photo",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  width: 110,
                  height: 110,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepWrapper({required Widget child}) {
    final media = MediaQuery.of(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              media.viewInsets.bottom + media.padding.bottom + 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _stepHeader({required String title, required String image}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Image.asset(image, height: 100, fit: BoxFit.contain),
      ],
    );
  }
}
