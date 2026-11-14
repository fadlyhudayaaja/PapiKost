enum VerificationDocumentKind { ktp, certificate, property }

extension VerificationDocumentKindX on VerificationDocumentKind {
  String get label => switch (this) {
    VerificationDocumentKind.ktp => 'Foto KTP',
    VerificationDocumentKind.certificate => 'Sertifikat Properti',
    VerificationDocumentKind.property => 'Foto Kost',
  };
}
