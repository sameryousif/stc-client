# STC Client

A cross-platform Flutter application for managing e-invoicing workflows in compliance with Sudan's tax authority (STC) system. The app handles the full lifecycle of a compliant electronic invoice — from PKI certificate enrollment, to UBL XML generation, XAdES digital signing, QR code embedding, and invoice submission (clearance or reporting) to the STC backend.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Usage](#usage)
- [Screens & Navigation](#screens--navigation)
- [Core Services](#core-services)
- [State Management](#state-management)
- [Bundled Tools](#bundled-tools)
- [File & Data Storage](#file--data-storage)
- [API Endpoints](#api-endpoints)
- [Dependencies](#dependencies)
- [Platform Support](#platform-support)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

STC Client is a Flutter desktop/mobile application that allows businesses to:

1. **Enroll** with the STC PKI infrastructure by generating an RSA key pair and a Certificate Signing Request (CSR), then submitting it to receive an X.509 digital certificate.
2. **Build invoices** in UBL (Universal Business Language) XML format, populated with supplier, customer, and line-item data.
3. **Sign invoices** using XAdES-compliant digital signatures backed by the enrolled certificate and private key.
4. **Generate QR codes** that encode invoice summary data for verification.
5. **Submit invoices** to the STC server via clearance (B2B) or reporting (B2C) endpoints.
6. **Test** all of the above in a **Sandbox environment** before going live.

---

## Features

- RSA 2048-bit key pair and DER-formatted CSR generation (via bundled OpenSSL)
- X.509 certificate enrollment via STC enrollment API
- UBL-compliant XML invoice generation with auto-incremented ICV and chained previous-invoice hash
- XAdES digital signature injection via bundled `stc-cli` tool
- C14N (XML canonicalization) as part of the signing pipeline
- QR code generation and display for signed invoices
- B2B Clearance and B2C Reporting invoice submission
- Sandbox mode for testing enrollment and invoice submission without production consequences
- Responsive UI (side-by-side layout on wide screens, stacked on narrow screens)
- Local SQLite database for invoice history and chaining data
- Persistent local storage for certificates, keys, CSR, and signed XML files

---

## Architecture

The project follows a layered architecture:

```
Presentation Layer  →  Application Layer  →  Service Layer  →  Core / Utils
  (screens/widgets)      (controllers)          (services)       (models, paths)
```

- **Presentation**: Flutter widgets and screens that render the UI and respond to user input.
- **Application (Controllers)**: Mediators between the UI and services. Hold `ValueNotifier`s to reactively update the UI.
- **Services**: Business logic — cryptography, API calls, invoice preparation, file I/O.
- **Core**: Pure data models (`InvoiceItem`, `EnrollmentSubject`, `CertInfo`) and XML/QR generation utilities.
- **State (Providers)**: `ChangeNotifier`-based providers (`InvoiceProvider`, `CertificateProvider`) for app-wide state via the `provider` package.
- **Utils**: Path resolution helpers (`AppPaths`, `ToolPaths`) for platform-specific file locations.

---

## Project Structure

```
stc-client/
├── assets/
│   └── tools/
│       ├── linux/
│       │   └── stc-cli              # CLI signing tool (Linux)
│       └── windows/
│           ├── stc-cli.exe          # CLI signing tool (Windows)
│           └── openssl.exe          # Bundled OpenSSL (Windows)
├── lib/
│   ├── main.dart                    # App entry point, DI setup, FFI init
│   ├── app.dart                     # MaterialApp, route definitions
│   ├── application/
│   │   └── controllers/
│   │       ├── enrollment_controller.dart   # CSR generation & cert enrollment
│   │       ├── invoice_controller.dart      # Invoice form state & totals
│   │       └── sandBox_controller.dart      # Sandbox orchestration
│   ├── core/
│   │   ├── certificate/
│   │   │   └── cert_info.dart       # X.509 cert detail extraction via OpenSSL
│   │   ├── invoice/
│   │   │   ├── invoice_item.dart    # Invoice line-item model
│   │   │   └── xml_generator.dart   # UBL XML document builder
│   │   ├── qr/
│   │   │   └── qr_genrator.dart     # QR code data generator
│   │   ├── enrollment_result.dart   # Result model for CSR generation
│   │   └── enrollment_subject.dart  # X.509 subject fields model
│   ├── models/
│   │   └── data_model.dart          # Supplier & Customer data models
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── enrollment_page.dart # Certificate enrollment UI
│   │   │   ├── invoice_page.dart    # Invoice creation & submission UI
│   │   │   └── sandBoxPage.dart     # Sandbox testing UI
│   │   └── widgets/
│   │       ├── enrollment/          # Enrollment panel & subject field widgets
│   │       ├── invoice/             # Supplier, customer, items, totals, action buttons
│   │       ├── qr/                  # QR code display widget
│   │       ├── sandbox/             # Sandbox enroll & invoice test widgets
│   │       ├── custom_field.dart
│   │       ├── item_card.dart
│   │       ├── preview.dart
│   │       ├── section_title.dart
│   │       └── totals_row.dart
│   ├── services/
│   │   ├── api_service.dart                  # Dio-based HTTP client (clearance, reporting, enrollment)
│   │   ├── certificateEnrollService.dart     # High-level cert enrollment flow
│   │   ├── crypto_service.dart               # Key/CSR generation via OpenSSL subprocess
│   │   ├── enrollment_service.dart           # Orchestrates CSR generation & cert loading
│   │   ├── file_service.dart                 # Generic file read/write helpers
│   │   ├── invoicePrepService.dart           # Invoice generation, signing, XAdES injection
│   │   └── invoice_processing_service.dart   # SQLite invoice history & chaining
│   ├── state/
│   │   └── providers/
│   │       ├── CertificateProvider.dart      # App-wide cert/key state
│   │       └── InvoiceProvider.dart          # Invoice generation & submission state
│   └── utils/
│       └── paths/
│           ├── app_paths.dart    # Paths for cert, key, CSR, XML, working dirs
│           └── tools_paths.dart  # Paths for stc-cli and OpenSSL; asset extraction
├── android/                     # Android platform project
├── ios/                         # iOS platform project
├── linux/                       # Linux desktop platform project
├── macos/                       # macOS desktop platform project
├── windows/                     # Windows desktop platform project
├── web/                         # Web platform project
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Prerequisites

- **Flutter SDK** `^3.7.2` (Dart SDK `^3.7.2`)
- **OpenSSL** installed and on `PATH` (Linux/macOS). On Windows, a bundled `openssl.exe` is used automatically.
- **Git**

Verify your Flutter setup:

```bash
flutter doctor
```

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/sameryousif/stc-client.git
cd stc-client
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the application

**Desktop (recommended — Linux, Windows, or macOS):**

```bash
flutter run -d linux
flutter run -d windows
flutter run -d macos
```

**Android:**

```bash
flutter run -d android
```

**iOS:**

```bash
flutter run -d ios
```

**Web:**

```bash
flutter run -d chrome
```

> **Note:** Full functionality (OpenSSL subprocess calls, file system access for keys/certificates) requires a desktop or mobile target. Web support is partial.

### 4. Build for release

```bash
# Linux
flutter build linux --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Android APK
flutter build apk --release
```

---

## Configuration

### API Base URL

The STC server base URL is defined in `lib/services/api_service.dart`:

```dart
static const String _baserUrl = 'https://stc-server.onrender.com';
```

Update this to point to your own STC server if needed. The derived endpoints are:

| Purpose | Endpoint |
|---|---|
| Clearance (B2B) | `POST /clear` |
| Reporting (B2C) | `POST /report` |
| CSR Enrollment | `POST /enroll` |

### Default Subject (CSR)

When no subject fields are entered, the CSR defaults to:

```
/C=SD/ST=Khartoum/L=Khartoum/O=Organization/CN=My.Company.com/serialNumber=5003
```

This is configured in `lib/services/crypto_service.dart` and can be overridden from the Enrollment screen.

---

## Usage

### Sandbox Mode (Start Here)

The app launches directly into **Sandbox** mode, which provides a safe environment for testing without hitting production.

1. **Enroll (Sandbox):** Generate a CSR and use the displayed Base64 string to receive a test certificate token.
2. **Submit Invoice (Sandbox):** Paste a JSON invoice payload and submit it to the sandbox endpoint. The raw API response is shown inline.

### Full Workflow

Navigate to **Full Experience** (top-right of the Sandbox screen) to access the full production workflow:

#### Step 1 — Certificate Enrollment (`/enrollment`)

1. Fill in the X.509 subject fields: Common Name, Organization, Organizational Unit, Country, State, Locality, and Serial Number.
2. Tap **Generate CSR** — the app uses OpenSSL (bundled on Windows; system on Linux/macOS) to generate a 2048-bit RSA private key and a DER-encoded CSR. Both are stored locally.
3. The generated CSR (Base64) is displayed. Copy it or submit it directly.
4. Enter your enrollment **token** and tap **Enroll Certificate** — the CSR is sent to the STC server and the returned X.509 certificate is stored in the app's data directory.

#### Step 2 — Invoice Creation (`/invoice`)

1. Fill in **Supplier Info**: name, TIN, street, city, country, phone, email.
2. Fill in **Customer Info**: same fields.
3. Add **Line Items**: name, description, quantity, unit price, and tax rate (%). Subtotal, tax total, and grand total update in real time.
4. Choose invoice type:
   - **Generate Clearance (B2B)** — for invoices above the clearance threshold.
   - **Generate Reporting (B2C)** — for simplified tax invoices.
5. The app:
   - Builds a UBL-compliant XML document.
   - Computes the ICV (Invoice Counter Value) from local history.
   - Chains the previous invoice hash (SHA-256).
   - Runs C14N canonicalization via `stc-cli`.
   - Injects the XAdES digital signature using the stored private key and certificate.
   - Embeds a QR code in the signed XML.
   - Stores the invoice in local SQLite for future chaining.
6. Tap **Submit** to send the signed invoice to the STC server. The response (clearance status or reporting acknowledgment) is displayed.

---

## Screens & Navigation

| Route | Screen | Purpose |
|---|---|---|
| `/` (default) | `SandboxPage` | Quick-test enrollment and invoice submission in sandbox mode |
| `/enrollment` | `EnrollmentPage` | Full certificate enrollment UI |
| `/invoice` | `InvoicePage` | Full invoice creation, signing, and submission UI |

---

## Core Services

### `ApiService`
Singleton Dio-based HTTP client. Handles:
- `sendClear(dto, {isSandbox})` — POST to `/clear`
- `sendReport(dto, {isSandbox})` — POST to `/report`
- `sendCsr(csrFile, token)` — POST to `/enroll`, returns Base64 certificate string

Sandbox mode is indicated by setting the `X-Sandbox-Mode: true` header.

### `CryptoService`
Wraps OpenSSL subprocess calls:
- `generateKeyAndCsr(subject)` — generates `private_key.pem` and `csr.der` in the app data directory.
- `readPrivateKey()`, `readCsr()`, `readCertificate()` — file read helpers.

### `EnrollmentService`
Orchestrates the enrollment process:
- `generateCsr(EnrollmentSubject)` — calls `CryptoService` and returns Base64 CSR.
- `loadCertificate()` / `loadPrivateKey()` — loads persisted credentials.

### `InvoicePrepService`
The most complex service. Responsible for:
- `generateUnsignedInvoice(...)` — builds UBL XML with auto-ICV and previous-invoice chaining.
- `runCanonicalizationCli(inputPath, outputPath)` — invokes `stc-cli` for C14N.
- `generateAndSignInvoice(...)` — full pipeline: generate → canonicalize → sign → inject XAdES → embed QR.

### `InvoiceProcessingService`
SQLite-backed service (via `sqflite_common_ffi`) that persists invoice records for ICV counter management and previous-invoice hash chaining.

---

## State Management

The app uses the `provider` package with two top-level `ChangeNotifier` providers registered in `main.dart`:

| Provider | Responsibility |
|---|---|
| `CertificateProvider` | Tracks enrollment state: CSR, private key, and certificate values |
| `InvoiceProvider` | Tracks invoice generation/submission state: loading flags, signed XML, QR string, DTO |

Controllers (`EnrollmentController`, `InvoiceFormController`, `SandboxController`) use `ValueNotifier` for fine-grained reactive updates within their respective screens.

---

## Bundled Tools

Two native binaries are bundled as Flutter assets and extracted to the app's support directory at first launch (`ToolPaths.ensureToolsReady()`):

| Tool | Platform | Asset Path | Purpose |
|---|---|---|---|
| `stc-cli` | Linux | `assets/tools/linux/stc-cli` | XML canonicalization & XAdES signing |
| `stc-cli.exe` | Windows | `assets/tools/windows/stc-cli.exe` | XML canonicalization & XAdES signing |
| `openssl.exe` | Windows | `assets/tools/windows/openssl.exe` | RSA key/CSR generation |

On **Linux/macOS**, the system-installed OpenSSL (`/usr/bin/openssl`) is used. On **Windows**, the bundled `openssl.exe` is used.

The CLI binary is made executable after extraction on Linux:

```bash
chmod +x <app_support_dir>/tools/stc-cli
```

---

## File & Data Storage

All persistent files are stored under the app's support directory (`getApplicationSupportDirectory()`):

```
<app_support>/
└── stc_client/
    ├── private_key.pem      # RSA private key (PEM)
    ├── csr.der              # Certificate Signing Request (DER)
    ├── merchant.der         # Enrolled X.509 certificate (DER)
    ├── invoices/            # Invoice records (SQLite)
    ├── signatures/          # Signature files
    ├── cleared/             # Cleared invoice XML files
    └── work/
        ├── input.xml        # Unsigned invoice XML
        ├── output.xml       # Signed invoice XML
        ├── temp_invoice.xml
        ├── signed_props.xml
        └── signedInfo.xml
<app_support>/
└── tools/
    ├── stc-cli(.exe)        # Extracted CLI tool
    └── openssl.exe          # Extracted OpenSSL (Windows only)
```

---

## API Endpoints

All requests go to the base URL `https://stc-server.onrender.com`.

### `POST /enroll`

Enroll a certificate by submitting a CSR.

**Request body:**
```json
{
  "csr": "<base64-encoded DER CSR>",
  "token": "<enrollment token>"
}
```

**Response:**
```json
{
  "data": {
    "certificate": "<base64-encoded certificate>"
  }
}
```

### `POST /clear`

Submit a clearance (B2B) invoice.

**Headers (sandbox):** `X-Sandbox-Mode: true`

**Request body:** Invoice DTO (JSON).

### `POST /report`

Submit a reporting (B2C) invoice.

**Headers (sandbox):** `X-Sandbox-Mode: true`

**Request body:** Invoice DTO (JSON).

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | UI framework |
| `provider` | `^6.0.5` | State management |
| `dio` | `^5.9.0` | HTTP client |
| `http` | `^1.2.0` | Supplementary HTTP |
| `xml` | `^6.5.0` | XML parsing & building |
| `uuid` | `^3.0.7` | UUID generation for invoice IDs |
| `crypto` | `^3.0.2` | SHA-256 hashing (invoice chaining) |
| `pointycastle` | `^4.0.0` | Cryptographic primitives |
| `basic_utils` | `^5.8.2` | X.509 / PKI utilities |
| `x509` | `^0.2.4+3` | X.509 certificate parsing |
| `qr_flutter` | `^4.1.0` | QR code rendering |
| `mobile_scanner` | `^5.2.3` | QR code scanning |
| `sqflite` | `^2.2.8+4` | SQLite (mobile) |
| `sqflite_common_ffi` | latest | SQLite via FFI (desktop) |
| `path_provider` | `^2.1.5` | Platform-specific path resolution |
| `path` | `^1.9.1` | Path manipulation |
| `file_picker` | `^10.3.8` | File selection dialogs |

---

## Platform Support

| Platform | Status | Notes |
|---|---|---|
| Linux | ✅ Full | System OpenSSL required (`/usr/bin/openssl`) |
| Windows | ✅ Full | Bundled OpenSSL and stc-cli |
| macOS | ⚠️ Partial | System OpenSSL required; entitlements may need adjustment |
| Android | ⚠️ Partial | Subprocess calls (OpenSSL) not supported; enrollment flow limited |
| iOS | ⚠️ Partial | Same limitations as Android |
| Web | ⚠️ Partial | No file system or subprocess access; UI only |

---

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes with clear messages: `git commit -m "feat: add your feature"`
4. Push to your fork: `git push origin feature/your-feature-name`
5. Open a Pull Request against `main`.

Please make sure your code passes `flutter analyze` before submitting.

---

## License

MIT License © 2026 [sameryousif](https://github.com/sameryousif)
