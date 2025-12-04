import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';

// Document Status Enum
enum DocumentStatus {
  pending,
  verified,
  rejected,
}

// Document State
class DocumentState {
  final File? licenseFront;
  final File? licenseBack;
  final File? vehicleFront;
  final File? vehicleBack;
  final File? vehicleSide;
  final File? insurance;
  final File? vehicleRegistration;
  final bool isSubmitting;
  final DocumentStatus licenseStatus;
  final DocumentStatus vehicleFrontStatus;
  final DocumentStatus vehicleBackStatus;
  final DocumentStatus vehicleSideStatus;
  final DocumentStatus insuranceStatus;
  final DocumentStatus vehicleRegistrationStatus;
  final String? licenseRejectionReason;
  final String? vehicleFrontRejectionReason;
  final String? vehicleBackRejectionReason;
  final String? vehicleSideRejectionReason;
  final String? insuranceRejectionReason;
  final String? vehicleRegistrationRejectionReason;

  const DocumentState({
    this.licenseFront,
    this.licenseBack,
    this.vehicleFront,
    this.vehicleBack,
    this.vehicleSide,
    this.insurance,
    this.vehicleRegistration,
    this.isSubmitting = false,
    this.licenseStatus = DocumentStatus.pending,
    this.vehicleFrontStatus = DocumentStatus.pending,
    this.vehicleBackStatus = DocumentStatus.pending,
    this.vehicleSideStatus = DocumentStatus.pending,
    this.insuranceStatus = DocumentStatus.pending,
    this.vehicleRegistrationStatus = DocumentStatus.pending,
    this.licenseRejectionReason,
    this.vehicleFrontRejectionReason,
    this.vehicleBackRejectionReason,
    this.vehicleSideRejectionReason,
    this.insuranceRejectionReason,
    this.vehicleRegistrationRejectionReason,
  });

  DocumentState copyWith({
    File? licenseFront,
    File? licenseBack,
    File? vehicleFront,
    File? vehicleBack,
    File? vehicleSide,
    File? insurance,
    File? vehicleRegistration,
    bool? isSubmitting,
    DocumentStatus? licenseStatus,
    DocumentStatus? vehicleFrontStatus,
    DocumentStatus? vehicleBackStatus,
    DocumentStatus? vehicleSideStatus,
    DocumentStatus? insuranceStatus,
    DocumentStatus? vehicleRegistrationStatus,
    String? licenseRejectionReason,
    String? vehicleFrontRejectionReason,
    String? vehicleBackRejectionReason,
    String? vehicleSideRejectionReason,
    String? insuranceRejectionReason,
    String? vehicleRegistrationRejectionReason,
  }) {
    return DocumentState(
      licenseFront: licenseFront ?? this.licenseFront,
      licenseBack: licenseBack ?? this.licenseBack,
      vehicleFront: vehicleFront ?? this.vehicleFront,
      vehicleBack: vehicleBack ?? this.vehicleBack,
      vehicleSide: vehicleSide ?? this.vehicleSide,
      insurance: insurance ?? this.insurance,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      licenseStatus: licenseStatus ?? this.licenseStatus,
      vehicleFrontStatus: vehicleFrontStatus ?? this.vehicleFrontStatus,
      vehicleBackStatus: vehicleBackStatus ?? this.vehicleBackStatus,
      vehicleSideStatus: vehicleSideStatus ?? this.vehicleSideStatus,
      insuranceStatus: insuranceStatus ?? this.insuranceStatus,
      vehicleRegistrationStatus: vehicleRegistrationStatus ?? this.vehicleRegistrationStatus,
      licenseRejectionReason: licenseRejectionReason ?? this.licenseRejectionReason,
      vehicleFrontRejectionReason: vehicleFrontRejectionReason ?? this.vehicleFrontRejectionReason,
      vehicleBackRejectionReason: vehicleBackRejectionReason ?? this.vehicleBackRejectionReason,
      vehicleSideRejectionReason: vehicleSideRejectionReason ?? this.vehicleSideRejectionReason,
      insuranceRejectionReason: insuranceRejectionReason ?? this.insuranceRejectionReason,
      vehicleRegistrationRejectionReason: vehicleRegistrationRejectionReason ?? this.vehicleRegistrationRejectionReason,
    );
  }

  bool get canSubmit {
    return licenseFront != null && 
           licenseBack != null && 
           vehicleFront != null &&
           vehicleBack != null &&
           vehicleSide != null &&
           insurance != null &&
           vehicleRegistration != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentState &&
        other.licenseFront == licenseFront &&
        other.licenseBack == licenseBack &&
        other.vehicleFront == vehicleFront &&
        other.vehicleBack == vehicleBack &&
        other.vehicleSide == vehicleSide &&
        other.insurance == insurance &&
        other.vehicleRegistration == vehicleRegistration &&
        other.isSubmitting == isSubmitting &&
        other.licenseStatus == licenseStatus &&
        other.vehicleFrontStatus == vehicleFrontStatus &&
        other.vehicleBackStatus == vehicleBackStatus &&
        other.vehicleSideStatus == vehicleSideStatus &&
        other.insuranceStatus == insuranceStatus &&
        other.vehicleRegistrationStatus == vehicleRegistrationStatus &&
        other.licenseRejectionReason == licenseRejectionReason &&
        other.vehicleFrontRejectionReason == vehicleFrontRejectionReason &&
        other.vehicleBackRejectionReason == vehicleBackRejectionReason &&
        other.vehicleSideRejectionReason == vehicleSideRejectionReason &&
        other.insuranceRejectionReason == insuranceRejectionReason &&
        other.vehicleRegistrationRejectionReason == vehicleRegistrationRejectionReason;
  }

  @override
  int get hashCode {
    return Object.hash(
      licenseFront,
      licenseBack,
      vehicleFront,
      vehicleBack,
      vehicleSide,
      insurance,
      vehicleRegistration,
      isSubmitting,
      licenseStatus,
      vehicleFrontStatus,
      vehicleBackStatus,
      vehicleSideStatus,
      insuranceStatus,
      vehicleRegistrationStatus,
      licenseRejectionReason,
      vehicleFrontRejectionReason,
      vehicleBackRejectionReason,
      vehicleSideRejectionReason,
      insuranceRejectionReason,
      vehicleRegistrationRejectionReason,
    );
  }
}

// Document Cubit
class DocumentCubit extends Cubit<DocumentState> {
  DocumentCubit() : super(const DocumentState());

  void setLicenseFront(File? file) {
    emit(state.copyWith(licenseFront: file));
  }

  void setLicenseBack(File? file) {
    emit(state.copyWith(licenseBack: file));
  }

  void setVehicleFront(File? file) {
    emit(state.copyWith(vehicleFront: file));
  }

  void setVehicleBack(File? file) {
    emit(state.copyWith(vehicleBack: file));
  }

  void setVehicleSide(File? file) {
    emit(state.copyWith(vehicleSide: file));
  }

  void setInsurance(File? file) {
    emit(state.copyWith(insurance: file));
  }

  void setVehicleRegistration(File? file) {
    emit(state.copyWith(vehicleRegistration: file));
  }

  void setSubmitting(bool isSubmitting) {
    emit(state.copyWith(isSubmitting: isSubmitting));
  }

  void setLicenseStatus(DocumentStatus status, {String? rejectionReason}) {
    emit(state.copyWith(
      licenseStatus: status,
      licenseRejectionReason: rejectionReason,
    ));
  }

  void setVehicleFrontStatus(DocumentStatus status, {String? rejectionReason}) {
    emit(state.copyWith(
      vehicleFrontStatus: status,
      vehicleFrontRejectionReason: rejectionReason,
    ));
  }

  void setVehicleBackStatus(DocumentStatus status, {String? rejectionReason}) {
    emit(state.copyWith(
      vehicleBackStatus: status,
      vehicleBackRejectionReason: rejectionReason,
    ));
  }

  void setVehicleSideStatus(DocumentStatus status, {String? rejectionReason}) {
    emit(state.copyWith(
      vehicleSideStatus: status,
      vehicleSideRejectionReason: rejectionReason,
    ));
  }

  void setInsuranceStatus(DocumentStatus status, {String? rejectionReason}) {
    emit(state.copyWith(
      insuranceStatus: status,
      insuranceRejectionReason: rejectionReason,
    ));
  }

  void setVehicleRegistrationStatus(DocumentStatus status, {String? rejectionReason}) {
    emit(state.copyWith(
      vehicleRegistrationStatus: status,
      vehicleRegistrationRejectionReason: rejectionReason,
    ));
  }

  Future<void> submitForReview() async {
    if (!state.canSubmit) return;

    emit(state.copyWith(isSubmitting: true));

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(isSubmitting: false));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false));
      rethrow;
    }
  }
}
