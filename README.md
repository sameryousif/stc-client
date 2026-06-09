# STC Client

STC Client is a Flutter application for working with Sudan Tax Authority electronic invoices. It supports certificate enrollment, UBL invoice generation, XAdES signing, QR code embedding, and invoice submission for clearance or reporting.

The app is built around the STC invoice lifecycle:

1. Generate an RSA private key and DER CSR.
2. Enroll the CSR to receive an X.509 merchant certificate.
3. Create a UBL invoice with supplier, customer, and line-item data.
4. Canonicalize and sign the invoice with XAdES/RSA-SHA256.
5. Embed a TLV Base64 QR payload.
6. Submit the invoice to the STC backend for clearance or reporting.

For implementation details, see [`technical_doc.md`](technical_doc.md).

## Features

| Area | What It Does |
|---|---|
| Certificate enrollment | Generates a private key and CSR, submits the CSR with an enrollment token, and stores the returned certificate locally. |
| Invoice authoring | Captures invoice metadata, supplier/customer details, line items, totals, and tax amounts. |
| UBL XML generation | Produces UBL invoice XML with ICV and previous invoice hash references. |
| XAdES signing | Canonicalizes XML, hashes signed sections, signs `SignedInfo`, and injects the signature into `UBLExtensions`. |
| QR generation | Builds a TLV Base64 QR payload from invoice totals, hash, signature, and certificate data. |
| Clearance/reporting | Sends signed invoice DTOs to `/prod/invoices/clear` or `/prod/invoices/report` and records successful submissions locally. |
| Local history | Uses SQLite to track invoice hashes and ICV values for invoice chaining. |

## Supported Platforms

This project is a Flutter app with desktop-oriented signing and file-system workflows.

| Platform | Status |
|---|---|
| Linux | Primary supported development target. Uses bundled `stc-cli` and system OpenSSL at `/usr/bin/openssl`. |
| Windows | Supported through bundled `stc-cli.exe` and `openssl.exe`. |
| macOS | Flutter scaffold exists, but signing currently depends on the Linux `stc-cli` asset path and `/usr/bin/openssl`; validate before production use. |
| Android/iOS/Web | Project scaffolds may exist, but the native subprocess signing pipeline is not currently documented as supported for production use. |

## Requirements

| Requirement | Version / Notes |
|---|---|
| Flutter SDK | Dart SDK `^3.7.2` as defined in `pubspec.yaml`. |
| OpenSSL | Required for key generation, CSR creation, certificate inspection, and signing. Windows uses bundled OpenSSL; Linux expects `/usr/bin/openssl`. |
| Bundled STC CLI | Included under `assets/tools/` for XML canonicalization. |
| Network access | Required for enrollment, clearance, and reporting API calls. |

Verify the Flutter environment:

```bash
flutter doctor
```

## Setup

```bash
git clone https://github.com/sameryousif/stc-client.git
cd stc-client
flutter pub get
```

Run on Linux:

```bash
flutter run -d linux
```

Run on Windows:

```bash
flutter run -d windows
```

Build release artifacts:

```bash
flutter build linux --release
flutter build windows --release
```

## Usage

### Home Page

The app opens on the home page, which presents two options:

- **Go to Enrollment** — navigate to the certificate enrollment screen.
- **Go to Invoice Generation** — navigate to the invoice generation and submission screen.

### Enrollment Flow

1. On the enrollment screen, enter the X.509 subject fields for the merchant.
2. Generate the CSR and private key.
3. Enter the enrollment token issued by the authority.
4. Submit the CSR and save the returned certificate locally.

Generated enrollment files are stored in the application support directory, not in the repository.

### Invoice Flow

1. Open the invoice screen.
2. Fill invoice, supplier, customer, and item data.
3. Generate either a reporting invoice or a clearance invoice.
4. Review the signed XML or JSON DTO preview.
5. Submit with `Report` or `Clear`.
6. Successful submissions update the local SQLite invoice history used for ICV and previous-hash chaining.

## Configuration

The API base URL is currently hardcoded in `lib/services/api_service.dart`:

```dart
static const String _baserUrl = 'https://stc-server.onrender.com';
```

Derived endpoints:

| Operation | Endpoint |
|---|---|
| Enrollment | `POST /prod/enrollment/enroll` |
| Clearance | `POST /prod/invoices/clear` |
| Reporting | `POST /prod/invoices/report` |

## Local Files

The app uses `path_provider` to resolve the application support directory and then creates an `stc_client` folder inside it.

Important generated files include:

| File | Purpose |
|---|---|
| `private_key.pem` | RSA private key generated during enrollment. |
| `csr.der` | DER-encoded certificate signing request. |
| `merchant.der` | Enrolled merchant certificate. |
| `invoices/invoice_*.xml` | Locally generated signed invoices. |
| `cleared/invoice_*.xml` | Server-returned cleared invoice copies. |
| `work/*.xml` | Temporary canonicalization and signing artifacts. |

## Development

Run tests:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

Regenerate Mockito mocks when API service tests change:

```bash
dart run build_runner build
```

## Project Layout

```text
lib/
  app.dart                         MaterialApp and routes
  main.dart                        Startup, providers, tool preparation
  application/controllers/         Screen controllers
  core/                            Invoice, QR, certificate, and enrollment logic
  models/                          Supplier and customer models
  presentation/                    Flutter screens and widgets
  services/                        API, crypto, file, enrollment, invoice processing services
  state/providers/                 ChangeNotifier app state
  utils/paths/                     Runtime file and tool path resolution
test/                              Unit and widget tests
assets/tools/                      Bundled native CLI/OpenSSL binaries
```

## Documentation

- [`technical_doc.md`](technical_doc.md): architecture, data flow, signing pipeline, API contract, local storage, and testing notes.
- `lib/services/api_service.dart`: current API endpoint configuration.
- `lib/utils/paths/app_paths.dart`: generated file locations.
- `lib/utils/paths/tools_paths.dart`: native tool extraction and path resolution.
