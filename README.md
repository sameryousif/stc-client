# STC Client 

> A cross-platform Flutter application for managing the full lifecycle of STC-compliant electronic invoices — from PKI certificate enrollment through XAdES digital signing, UBL XML generation, and submission to the Sudan Tax Authority backend.

**Flutter 3.7+ · Dart 3.7+ · XAdES Signing · UBL XML · PKI / X.509 · Linux · Windows · macOS**

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Architecture](#2-architecture)
3. [Project Structure](#3-project-structure)
4. [Prerequisites](#4-prerequisites)
5. [Installation](#5-installation)
6. [Configuration](#6-configuration)
7. [Data Models](#7-data-models)
8. [XML Generator](#8-xml-generator)
9. [QR Generator](#9-qr-generator)
10. [CryptoService](#10-cryptoservice)
11. [EnrollmentService](#11-enrollmentservice)
12. [InvoicePrepService](#12-invoiceprepservice)
13. [InvoiceProcessingService](#13-invoiceprocessingservice)
14. [ApiService](#14-apiservice)
15. [Controllers](#15-controllers)
16. [Providers](#16-providers)
17. [Enrollment Flow](#17-enrollment-flow)
18. [Invoice Flow](#18-invoice-flow)
19. [XAdES Signing Pipeline](#19-xades-signing-pipeline)
20. [API Reference](#20-api-reference)
21. [File Paths](#21-file-paths)
22. [Bundled Tools](#22-bundled-tools)
23. [Test Suite](#23-test-suite)
24. [Dependencies](#24-dependencies)

---

## 1. Introduction

STC Client enables businesses to comply with Sudan's electronic invoicing mandate. The application handles four distinct concerns:

**1 — Identity: PKI Certificate Enrollment**
Generate an RSA-2048 key pair and a DER-encoded Certificate Signing Request (CSR), then submit it to the STC enrollment endpoint to receive a signed X.509 certificate identifying your business.

**2 — Authoring: UBL XML Invoice Generation**
Build a UBL 2.1-compliant XML invoice populated with supplier/customer data and line items, with automatic ICV (Invoice Counter Value) increment and SHA-256 chaining to the previous invoice hash.

**3 — Signing: XAdES Digital Signature**
Canonicalize the invoice via C14N, compute `SignedProperties` and `SignedInfo`, sign with RSA-SHA256 using the enrolled private key, and inject the full XAdES `ds:Signature` block plus a TLV-encoded QR code into the XML.

**4 — Submission: Clearance & Reporting**
Submit B2B invoices via the Clearance endpoint (STC validates and returns a stamped copy) or B2C invoices via the Reporting endpoint (STC records and acknowledges). Both modes are available in a Sandbox environment for testing.

---

## 2. Architecture

A strict four-layer architecture keeps UI, business logic, I/O, and data models independent.

```
┌─────────────────┬──────────────────┬───────────────────────┬──────────────────────┐
│  Presentation   │   Application    │        Service        │     Core / Utils     │
│─────────────────│──────────────────│───────────────────────│──────────────────────│
│  Screens        │  Controllers     │  Crypto · API         │  Models · XML        │
│  Widgets        │  Providers       │  Invoice · File       │  QR · Paths          │
└─────────────────┴──────────────────┴───────────────────────┴──────────────────────┘
```

| Layer | Responsibility | Key files |
|---|---|---|
| `presentation/` | Flutter widgets and screens. Renders UI, dispatches events to controllers. No business logic. | `sandbox_page`, `invoice_page`, `enrollment_page` |
| `application/` | Controllers mediate between UI and services. Hold `ValueNotifier`s for reactive updates. Providers manage app-wide state via `ChangeNotifier`. | `InvoiceFormController`, `EnrollmentController`, `InvoiceProvider` |
| `services/` | All I/O: file system, subprocesses (OpenSSL, stc-cli), HTTP (Dio), SQLite. Pure business logic. | `InvoicePrepService`, `ApiService`, `CryptoService` |
| `core/` | Pure data models and pure functions. No Flutter imports, no I/O. Freely unit-testable. | `InvoiceItem`, `EnrollmentSubject`, `xml_generator`, `qr_generator` |
| `utils/` | Platform-aware path resolution and tool extraction. No business logic. | `AppPaths`, `ToolPaths` |

> **Dependency direction:** Dependencies flow inward only — `presentation` depends on `application`, which depends on `services`, which depend on `core`. The `core` layer has no dependencies on any other layer.

---

## 3. Project Structure

```
stc-client/
├── assets/tools/
│   ├── linux/
│   │   └── stc-cli                          # C14N & XAdES CLI (Linux)
│   └── windows/
│       ├── stc-cli.exe                      # C14N & XAdES CLI (Windows)
│       └── openssl.exe                      # Bundled OpenSSL (Windows only)
│
├── lib/
│   ├── main.dart                            # Entry point: DI, FFI init, tool extraction
│   ├── app.dart                             # MaterialApp, route table
│   │
│   ├── core/
│   │   ├── certificate/
│   │   │   └── cert_info.dart               # X.509 detail extraction via OpenSSL
│   │   ├── invoice/
│   │   │   ├── invoice_item.dart            # Line-item domain model
│   │   │   └── xml_generator.dart           # UBL XML document builder
│   │   ├── qr/
│   │   │   └── qr_generator.dart            # TLV QR code encoder
│   │   ├── enrollment_subject.dart          # X.509 subject fields model
│   │   └── enrollment_result.dart           # CSR + private key result model
│   │
│   ├── models/
│   │   └── data_model.dart                  # Supplier & Customer models
│   │
│   ├── services/
│   │   ├── api_service.dart                 # Dio HTTP client (clear/report/enroll)
│   │   ├── certificateEnrollService.dart    # High-level cert enrollment + PEM→DER
│   │   ├── crypto_service.dart              # OpenSSL subprocess: key + CSR gen
│   │   ├── enrollment_service.dart          # CSR orchestration + file loading
│   │   ├── file_service.dart                # Generic file read/write + cert validation
│   │   ├── invoicePrepService.dart          # Full sign pipeline: generate→C14N→sign→XAdES→QR
│   │   └── invoice_processing_service.dart  # SQLite history + hash chaining
│   │
│   ├── application/controllers/
│   │   ├── invoice_controller.dart          # Invoice form state, totals, item CRUD
│   │   ├── enrollment_controller.dart       # CSR generation + cert enrollment
│   │   └── sandbox_controller.dart          # Sandbox test orchestration
│   │
│   ├── state/providers/
│   │   ├── InvoiceProvider.dart             # App-wide invoice generation/submission state
│   │   └── CertificateProvider.dart         # App-wide cert validity state
│   │
│   ├── presentation/screens/
│   │   ├── sandbox_page.dart                # Default screen: sandbox test mode
│   │   ├── invoice_page.dart                # Full invoice creation & submission
│   │   └── enrollment_page.dart             # Certificate enrollment UI
│   │
│   └── utils/paths/
│       ├── app_paths.dart                   # All file paths (cert, key, XML, working dir)
│       └── tools_paths.dart                 # Tool paths + asset extraction logic
│
└── test/
    ├── widget_test.dart                     # QR, InvoiceItem, removeSections, UBL XML
    ├── core/
    │   ├── invoice_item_test.dart           # Domain model unit tests
    │   ├── invoice_controller_test.dart     # Controller totals & state tests
    │   └── qr_generator_test.dart           # QR determinism & base64 tests
    └── services/
        ├── api_service_test.dart            # Mockito-based HTTP tests
        └── invoice_processing_test.dart     # XML section removal tests
```

---

## 4. Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Flutter SDK | ≥ 3.7.2 | Includes Dart SDK ≥ 3.7.2 |
| OpenSSL | any | Linux/macOS: must be on PATH at `/usr/bin/openssl`. Windows: bundled automatically. |
| stc-cli | bundled | Extracted from `assets/tools/` at first launch. No manual install needed. |
| Git | any | For cloning the repository. |

Verify your Flutter environment:

```bash
flutter doctor
```

---

## 5. Installation

### Clone & Install

```bash
git clone https://github.com/sameryousif/stc-client.git
cd stc-client
flutter pub get
```

### Run (Development)

```bash
# Linux (recommended)
flutter run -d linux

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Android
flutter run -d android
```

> **Note:** Full functionality (OpenSSL subprocess, file system access for keys and certificates) requires a desktop or Android target. Web support is UI-only; subprocess calls are not available in a browser context.

### Build (Release)

```bash
flutter build linux   --release
flutter build windows --release
flutter build macos   --release
flutter build apk     --release
```

### Run Tests

```bash
flutter test
```

---

## 6. Configuration

### API Base URL

Defined as a constant in `lib/services/api_service.dart`:

```dart
static const String _baserUrl = 'https://stc-server.onrender.com';
```

Change this to point to your own STC server instance. The three derived endpoints (`/clear`, `/report`, `/enroll`) are built from this base.

### Default CSR Subject

When no subject fields are entered on the enrollment screen, the CSR falls back to a default subject defined in `CryptoService.generateKeyAndCsr()`:

```
/C=SD/ST=Khartoum/L=Khartoum/O=Organization/CN=My.Company.com/serialNumber=5003
```

In production, users must fill in their actual organization details before generating the CSR.

---

## 7. Data Models

Pure Dart classes in `lib/core/` and `lib/models/`. No Flutter imports, no I/O. All freely unit-testable.

### InvoiceItem

Represents a single line item on an invoice.

```dart
class InvoiceItem {
  String name;
  String description;
  int    quantity;
  double unitPrice;
  double taxRate;      // percentage, e.g. 15.0 for 15%

  double get total => quantity * unitPrice;
}
```

> `total` is the pre-tax line total. Tax amount = `total * taxRate / 100`. This is computed in `InvoiceFormController.recalculateTotals()`, not in the model itself.

### Supplier & Customer

Both models in `lib/models/data_model.dart` carry identical fields:

| Field | Type | Description |
|---|---|---|
| `name` | String | Legal business name |
| `tin` | String | Tax Identification Number (VAT number) |
| `street` | String | Street address |
| `city` | String | City |
| `country` | String | ISO 3166-1 alpha-2 country code (e.g. `SD`) |
| `phone` | String | Contact phone number |
| `email` | String | Contact email address |

### EnrollmentSubject

Maps directly to X.509 distinguished name fields used when generating the CSR:

```dart
class EnrollmentSubject {
  final String cn;           // Common Name (e.g. My.Company.com)
  final String on;           // Organization Name
  final String ou;           // Organizational Unit
  final String c;            // Country (2-letter ISO code)
  final String st;           // State / Province
  final String l;            // Locality (City)
  final String serialNumber; // Entity serial number
}
```

### EnrollmentResult

Returned by `EnrollmentController.generateCsr()`:

```dart
class EnrollmentResult {
  final String csrBase64;   // Base64-encoded DER CSR, ready for API submission
  final String privateKey;  // PEM private key string
}
```

### CertInfo

Populated by `extractCertDetails()` via OpenSSL subprocess, used during XAdES signing:

```dart
class CertInfo {
  final String issuerName;          // Full issuer DN string
  final String serialNumberDecimal; // Certificate serial as decimal string
}
```

---

## 8. XML Generator

`lib/core/invoice/xml_generator.dart` — builds a compliant UBL 2.1 Invoice XML document.

### generateUBLInvoice()

The primary function. Takes all invoice fields and returns a UBL-compliant XML string.

```dart
Future<String> generateUBLInvoice({
  required String invoiceNumber,
  required String uuid,
  required String issueDate,        // yyyy-MM-dd
  required String issueTime,        // HH:mm:ss
  required int    icv,              // Invoice Counter Value
  required String previousInvoiceHash,
  required String profileId,        // 'CLEARED' or 'REPORTED'
  // ... supplier fields, customer fields, items
})
```

The generated XML includes these UBL elements in order:

| Element | Content |
|---|---|
| `ext:UBLExtensions` | Placeholder for XAdES signature injection |
| `cbc:ProfileID` | `CLEARED` or `REPORTED` |
| `cbc:ID` | Invoice number |
| `cbc:UUID` | UUID v4 |
| `cac:AdditionalDocumentReference` (ICV) | Invoice Counter Value |
| `cac:AdditionalDocumentReference` (PIH) | Previous Invoice Hash (SHA-256, Base64) |
| `cac:AdditionalDocumentReference` (QR) | QR placeholder (populated after signing) |
| `cac:Signature` | Signature placeholder |
| `cac:AccountingSupplierParty` | Supplier details |
| `cac:AccountingCustomerParty` | Customer details |
| `cac:TaxTotal` | Aggregated tax amounts |
| `cac:LegalMonetaryTotal` | Subtotal and grand total |
| `cac:InvoiceLine` (×n) | One element per `InvoiceItem` |

---

## 9. QR Generator

`lib/core/qr/qr_generator.dart` — encodes invoice summary data as a TLV (Tag-Length-Value) Base64 string for the QR code.

```dart
String generateQr({
  required String    sellerName,
  required String    vatNumber,
  required DateTime  issueDate,
  required double    total,
  required double    vatTotal,
  required String    xmlHash,
  required Uint8List signature,
  required Uint8List certificate,
})
```

Each field is TLV-encoded as: `[tag byte][length byte][value bytes]`. The concatenated buffer is Base64-encoded. The function is **pure and deterministic** — identical inputs always produce identical output, verified by the test suite.

| Tag | Field | Encoding |
|---|---|---|
| `0x01` | Seller name | UTF-8 |
| `0x02` | VAT number | UTF-8 |
| `0x03` | Issue date/time | ISO 8601 UTC, UTF-8 |
| `0x04` | Invoice total | Formatted string, UTF-8 |
| `0x05` | VAT total | Formatted string, UTF-8 |
| `0x06` | XML hash | UTF-8 |
| `0x07` | Digital signature | Raw bytes |
| `0x08` | Certificate | Raw DER bytes |

---

## 10. CryptoService

`lib/services/crypto_service.dart` — wraps all OpenSSL subprocess calls for key and CSR generation.

### generateKeyAndCsr(subject)

Runs two sequential OpenSSL subprocesses:

```bash
# Step 1: Generate RSA-2048 private key
openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048

# Step 2: Generate DER-encoded CSR
openssl req -new -key private_key.pem -out csr.der -subj <subject_string> -outform DER
```

Both files are written to the app data directory via `AppPaths`. If either subprocess returns a non-zero exit code, an exception is thrown with the stderr content.

### File Accessors

| Method | Returns | Description |
|---|---|---|
| `getCsrFile()` | `Future<File?>` | CSR file, or null if not yet generated |
| `getPrivateKeyFile()` | `Future<File?>` | Private key file, or null if not yet generated |
| `getCertFile()` | `Future<File?>` | Certificate file, or null if not yet enrolled |
| `readPrivateKey()` | `Future<String>` | PEM string of the private key |
| `readCsr()` | `Future<Uint8List?>` | Raw DER bytes of the CSR |
| `readCertificate()` | `Future<Uint8List?>` | Raw DER bytes of the certificate |

---

## 11. EnrollmentService

`lib/services/enrollment_service.dart` — orchestrates the full PKI enrollment process.

| Method | Description |
|---|---|
| `generateCsr(EnrollmentSubject)` | Calls `CryptoService.generateKeyAndCsr()`, reads the resulting DER file, and returns the Base64-encoded CSR string ready for API submission. |
| `loadPrivateKey()` | Returns the PEM private key as a string from the local file. |
| `loadCertificate()` | Returns the Base64-encoded certificate, or `null` if not yet enrolled. |
| `getCsrFile()` | Returns the CSR `File` object needed for the API enrollment call. |

`CertEnrollService` wraps the API call itself. It checks if a valid certificate already exists before making a network request, and converts the returned PEM certificate to DER format via `pemToDer()` before saving it locally.

---

## 12. InvoicePrepService

`lib/services/invoicePrepService.dart` — the most complex service. Orchestrates the full invoice generation and signing pipeline.

### generateAndSignInvoice() — Top-Level Pipeline

```dart
Future<String> generateAndSignInvoice({
  invoiceNumber, items, supplierInfo, customerInfo, clearance
})
```

Executes 6 sequential steps and returns the path to the final signed XML file:

**Step 1 — Generate Unsigned Invoice**
Calls `generateUnsignedInvoice()` which fetches the current ICV and previous hash from SQLite, then builds a UBL XML document.

**Step 2 — Write to input.xml**
Serializes the `XmlDocument` to disk at `work/input.xml` in the app support directory.

**Step 3 — Canonicalize (C14N)**
Runs `stc-cli input.xml output.xml`. The CLI applies XML C14N canonicalization so the byte representation is deterministic before hashing and signing.

**Step 4 — Inject XAdES Signature**
Calls `injectXadesSignature()` — see [Section 19](#19-xades-signing-pipeline) for the full 8-step sub-pipeline.

**Step 5 — Save Signed XML**
Writes the signed invoice to `invoices/invoice_<number>.xml`.

**Step 6 — Embed QR Code**
Calls `generateQr()` and injects the resulting Base64 string into the `QR AdditionalDocumentReference` element of the saved XML.

### XadesResult

```dart
class XadesResult {
  final XmlDocument signedInvoice;    // Invoice with <ds:Signature> injected
  final Uint8List   signatureBytes;   // Raw RSA signature bytes
  final Uint8List   certificateBytes; // Raw DER certificate bytes
}
```

### Other Methods

| Method | Description |
|---|---|
| `generateUnsignedInvoice(...)` | Queries SQLite for ICV + previous hash, calls `generateUBLInvoice()`, returns `XmlDocument`. |
| `runCanonicalizationCli(input, output)` | Invokes `stc-cli` subprocess. Throws on non-zero exit code. |
| `computeHashBase64(path)` | SHA-256 of file at `path`, returned as Base64 string. |
| `signXml(xmlPath)` | Runs `openssl dgst -sha256 -sign` and returns the path to the `.sig` file. |
| `sendSignedInvoice({xmlContent, uuid})` | Builds the submission DTO: `{uuid, invoice_hash, invoice}`. |

---

## 13. InvoiceProcessingService

`lib/services/invoice_processing_service.dart` — SQLite-backed invoice history for ICV counter management and hash chaining.

### Database Schema

```sql
CREATE TABLE invoices (
  id            INTEGER  PRIMARY KEY AUTOINCREMENT,
  entityId      TEXT,     -- extracted from certificate CN
  icv           INTEGER,  -- Invoice Counter Value
  base64Invoice TEXT,     -- Base64-encoded invoice XML
  type          TEXT,     -- 'clearance' or 'reporting'
  hash          TEXT,     -- SHA-256 of canonicalized invoice
  createdAt     TEXT      -- ISO 8601 timestamp
)
```

### Key Methods

| Method | Description |
|---|---|
| `getLastInvoiceForEntityByType(entityId)` | Returns the last invoice record for this entity ordered by ICV descending. Used to compute the next ICV and previous invoice hash when generating a new invoice. |
| `processClearedInvoice(base64, prepService, entityId)` | Decodes the server-returned cleared invoice, saves it to the `cleared/` directory, strips signature sections, canonicalizes, computes hash, and records in SQLite. |
| `processReportedInvoice(base64, prepService, entityId)` | Same pipeline as above but without saving a cleared copy to disk. |
| `removeSections(XmlDocument)` | Static method. Removes `UBLExtensions`, `Signature`, and QR `AdditionalDocumentReference` from a document before canonicalization for hashing. |

---

## 14. ApiService

`lib/services/api_service.dart` — singleton Dio-based HTTP client with interceptor logging and sandbox mode support.

### Static Methods

| Method | Endpoint | Description |
|---|---|---|
| `sendClear(dto, {isSandbox})` | `POST /clear` | Submit a B2B clearance invoice. Passes `X-Sandbox-Mode: true` header when `isSandbox` is true. |
| `sendReport(dto, {isSandbox})` | `POST /report` | Submit a B2C reporting invoice. |
| `sendCsr({csrFile, token})` | `POST /enroll` | Enroll by uploading a Base64 CSR and enrollment token. Returns the certificate string from `response.data.data.certificate`. |
| `sendCsrSandbox({csr})` | `POST /enroll` | Sandbox variant — sends raw CSR body without token. |

### Dio Configuration

```
connectTimeout: 20s
receiveTimeout: 20s
validateStatus: status < 600   // Don't throw on 4xx/5xx; return response
Content-Type:   application/json
```

All request/response logging is wrapped in `if (kDebugMode)` — nothing is printed in release builds.

> **Testing:** The Dio instance is exposed via a `@visibleForTesting` setter, allowing Mockito to inject a mock in unit tests without modifying production code.

---

## 15. Controllers

Controllers mediate between the UI and the service layer. They hold `ValueNotifier`s for fine-grained reactive updates and are scoped to individual screens.

### InvoiceFormController

```dart
// Create in production (reads cert CN from disk asynchronously)
final controller = await InvoiceFormController.create();

// Create in tests (synchronous, no I/O)
final controller = InvoiceFormController.createForTest(
  supplier: ..., customer: ...
);
```

| Property / Method | Type | Description |
|---|---|---|
| `items` | `List<InvoiceItem>` | Current line items |
| `subtotal` | `ValueNotifier<double>` | Sum of all item totals (pre-tax) |
| `taxTotal` | `ValueNotifier<double>` | Sum of all item tax amounts |
| `grandTotal` | `ValueNotifier<double>` | subtotal + taxTotal |
| `addItem(item)` | void | Adds item and recalculates totals |
| `removeItem(index)` | void | Removes item at index and recalculates |
| `clearAll()` | void | Resets invoice number (new UUID) and date to now |
| `supplierInfo` | `Map<String, String>` | Supplier fields as a flat map for the service layer |
| `customerInfo` | `Map<String, String>` | Customer fields as a flat map for the service layer |

### EnrollmentController

| Method | Description |
|---|---|
| `generateCsr(EnrollmentSubject)` | Calls `EnrollmentService.generateCsr()` and returns an `EnrollmentResult` with the Base64 CSR and private key. |
| `enrollCertificate(token)` | Submits the existing CSR file and token to the STC API, then updates the `certificate` ValueNotifier. |
| `loadInitialData()` | Loads existing cert, key, and CSR from disk on screen init. Populates all three ValueNotifiers. |

### SandboxController

Orchestrates the sandbox test mode. Maintains loading state for sandbox enrollment and invoice submission, and exposes the raw API response text for display in `ResponseBox`.

---

## 16. Providers

App-wide state via `ChangeNotifier`. Both providers are registered in `main.dart` using `MultiProvider` and injected with their required services at startup.

### InvoiceProvider

Manages the full invoice generation and submission lifecycle.

```dart
// Key state flags
bool isGeneratingB2B  // clearance generation in progress
bool isGeneratingB2C  // reporting generation in progress
bool isSendingClear   // clearance submission in progress
bool isSendingReport  // reporting submission in progress
String? signedXml     // the final signed XML string
String? qrString      // Base64 QR data
```

| Method | Returns | Description |
|---|---|---|
| `generateAndSign(...)` | `Future<InvoiceResult>` | Runs the full sign pipeline and stores the signed XML. |
| `clearInvoice({isSandBox})` | `Future<InvoiceResult>` | Sends to `/clear`. On success: calls `processClearedInvoice()` to update SQLite history. |
| `reportInvoice({isSandBox})` | `Future<InvoiceResult>` | Sends to `/report`. On success: calls `processReportedInvoice()`. |
| `generateDtoFromXml()` | `Future<void>` | Builds the submission DTO from the current signed XML for preview. |
| `refreshInvoice()` | void | Resets all state flags and clears the signed XML for a new invoice. |

`InvoiceResult` is a simple value object: `{bool success, String message}`.

### CertificateProvider

A lightweight provider tracking whether the enrolled certificate is currently valid.

```dart
bool isCertificateValid  // read from FileService.isCertificateStillValid()

checkCertificate()                    // re-validates and notifies listeners
enrollCertificate(token, csrFile)     // delegates to CertEnrollService then re-checks
```

---

## 17. Enrollment Flow

End-to-end walkthrough of how a business registers with the STC PKI infrastructure.

**Step 1 — Fill in X.509 subject fields**
User enters Common Name, Organization, OU, Country, State, Locality, and Serial Number on the enrollment screen. These map directly to `EnrollmentSubject`.

**Step 2 — EnrollmentController.generateCsr()**
Calls `EnrollmentService → CryptoService`. OpenSSL generates a 2048-bit RSA key at `private_key.pem` and a DER CSR at `csr.der`. Both are stored in the app data directory. The Base64 CSR is displayed to the user.

**Step 3 — User enters enrollment token**
The token is provided by the STC authority and authorizes the CSR submission.

**Step 4 — EnrollmentController.enrollCertificate(token)**
Calls `CertEnrollService.enrollCertificate()` → `ApiService.sendCsr()`. Posts `{"csr": "<base64>", "token": "<token>"}` to `POST /enroll`.

**Step 5 — Certificate saved**
The returned PEM certificate is decoded from Base64, converted to DER format by `pemToDer()`, and saved as `merchant.der`. The UI updates via `CertificateProvider.checkCertificate()`.

---

## 18. Invoice Flow

End-to-end walkthrough from filling in invoice data to receiving a clearance/reporting response.

**Step 1 — Fill supplier, customer, and line items**
UI validates that TIN/VAT is present, quantity > 0, unit price ≥ 0, and tax rate is between 0–100. `InvoiceFormController` computes totals reactively via `ValueNotifier`.

**Step 2 — Tap "Generate Clearance" or "Generate Reporting"**
`InvoiceProvider.generateAndSign()` is called. `InvoicePrepService.generateAndSignInvoice()` runs the full 6-step pipeline (see [Section 12](#12-invoiceprepservice)).

**Step 3 — Preview signed XML & QR**
The signed XML is stored in `InvoiceProvider.signedXml`. The QR widget reads `qrString` and renders the code. The JSON DTO preview can be toggled.

**Step 4 — Tap "Clear" or "Report"**
`InvoiceProvider.clearInvoice()` or `reportInvoice()` builds the DTO: `{uuid, invoice_hash, invoice}` where `invoice` is Base64-encoded XML. Sends to `/clear` or `/report`.

**Step 5 — Process server response**
On HTTP 200: for clearance, the server-returned cleared invoice is decoded and saved via `processClearedInvoice()`; the invoice is recorded in SQLite for future ICV chaining. For reporting: `processReportedInvoice()` records the hash. On failure: the error message is displayed in the UI.

---

## 19. XAdES Signing Pipeline

`InvoicePrepService.injectXadesSignature()` implements a full XAdES-compliant digital signature across 8 steps.

**Step 1 — Hash the canonicalized invoice**
SHA-256 of `output.xml` (the C14N-normalized invoice). Result: `invoiceHashBase64`.

**Step 2 — Extract certificate details**
Runs `openssl x509 -issuer` and `openssl x509 -serial` to extract the issuer DN and serial number (hex → decimal) for the XAdES certificate reference.

**Step 3 — Build & canonicalize SignedProperties**
Constructs the `xades:SignedProperties` XML block with signing time, certificate digest, issuer name, and serial number. Writes to `signed_props.xml` and canonicalizes in-place via `stc-cli`.

**Step 4 — Hash SignedProperties**
SHA-256 of the canonicalized `signed_props.xml`. Result: `signedPropertiesHashBase64`.

**Step 5 — Build & canonicalize SignedInfo**
Constructs `ds:SignedInfo` referencing both `invoiceHashBase64` and `signedPropertiesHashBase64`. Writes to `signedInfo.xml` and canonicalizes in-place.

**Step 6 — Sign canonical SignedInfo with RSA-SHA256**
Runs:
```bash
openssl dgst -sha256 -sign private_key.pem -out signedInfo.sig signedInfo.xml
```
Reads the raw signature bytes and Base64-encodes them.

**Step 7 — Build XAdES ds:Signature element**
Assembles the complete `<ds:Signature>` XML element containing: canonical `SignedInfo`, `SignatureValue` (Base64), `KeyInfo` with the DER certificate, and `Object/QualifyingProperties` with `SignedProperties`.

**Step 8 — Inject into invoice XML**
Calls `injectSignature(invoice, signature)` which replaces the placeholder `<ext:UBLExtensions>` in the invoice with the full XAdES signature block.

---

## 20. API Reference

All requests target the base URL `https://stc-server.onrender.com`.

### POST /enroll — Certificate Enrollment

```json
// Request body
{
  "csr":   "<base64-encoded DER CSR>",
  "token": "<enrollment token>"
}

// Success response (200)
{
  "data": {
    "certificate": "<base64-encoded PEM certificate>"
  }
}
```

### POST /clear — Clearance (B2B)

```
// Optional header for sandbox mode
X-Sandbox-Mode: true
```

```json
// Request body
{
  "uuid":         "<invoice UUID>",
  "invoice_hash": "<SHA-256 Base64 of canonicalized invoice>",
  "invoice":      "<Base64-encoded signed XML>"
}

// Success response (200)
{
  "data": {
    "cleared_invoice": "<Base64 cleared invoice from STC>"
  }
}
```

### POST /report — Reporting (B2C)

Same request body structure as `/clear`. No `cleared_invoice` in the response body.

---

## 21. File Paths

All paths are resolved at runtime via `path_provider.getApplicationSupportDirectory()`.

| File | AppPaths method | Purpose |
|---|---|---|
| `stc_client/private_key.pem` | `privateKeyPath()` | RSA-2048 private key (PEM) |
| `stc_client/csr.der` | `csrPath()` | Certificate Signing Request (DER) |
| `stc_client/merchant.der` | `certPath()` | Enrolled X.509 certificate (DER) |
| `stc_client/invoices/invoice_*.xml` | `invoicesDir()` | Locally saved signed invoices |
| `stc_client/cleared/invoice_*.xml` | `clearedDir()` | Cleared invoice copies from STC server |
| `stc_client/work/input.xml` | `inputXmlPath()` | Unsigned invoice (before C14N) |
| `stc_client/work/output.xml` | `outputXmlPath()` | Canonicalized invoice (after C14N) |
| `stc_client/work/signed_props.xml` | `signedPropsPath()` | XAdES SignedProperties |
| `stc_client/work/signedInfo.xml` | `signedInfoPath()` | XAdES SignedInfo |
| `stc_client/work/temp_invoice.xml` | `tempInvoicePath()` | Temp file for post-submission processing |
| `tools/stc-cli(.exe)` | `ToolPaths.cliToolPath` | Extracted C14N/signing CLI tool |
| `tools/openssl.exe` | `ToolPaths.opensslPath` | Extracted OpenSSL (Windows only) |

---

## 22. Bundled Tools

Two native binaries are shipped as Flutter assets and extracted to the app support directory by `ToolPaths.ensureToolsReady()` on first launch.

| Tool | Platform | Asset Path | Purpose |
|---|---|---|---|
| `stc-cli` | Linux | `assets/tools/linux/stc-cli` | XML C14N canonicalization |
| `stc-cli.exe` | Windows | `assets/tools/windows/stc-cli.exe` | XML C14N canonicalization |
| `openssl.exe` | Windows | `assets/tools/windows/openssl.exe` | Key/CSR generation & signing |

On Linux, `chmod +x` is applied to `stc-cli` after extraction. On Linux/macOS, the system OpenSSL at `/usr/bin/openssl` is used directly — no extraction needed.

> **First launch:** Tool extraction happens asynchronously before `runApp()`. If extraction fails, `ToolPaths.verifyToolsExist()` throws with the missing tool path, preventing the app from starting in a broken state.

---

## 23. Test Suite

995 lines across 5 test files covering the pure, unit-testable surface of the codebase.

| File | Lines | What's tested |
|---|---|---|
| `widget_test.dart` | 435 | QR determinism & base64 validity; `InvoiceItem` calculations; `removeSections()` all branches; `generateUBLInvoice()` XML structure (6 tests: invoice number, ProfileID, namespaces, ICV, supplier/customer names, line item totals) |
| `core/invoice_controller_test.dart` | 158 | Single-item subtotal/tax/grand total; multi-item with mixed tax rates; item removal recalculation; zero-quantity edge case; `supplierInfo`/`customerInfo` maps; `clearAll()` reset |
| `services/invoice_processing_test.dart` | 88 | `UBLExtensions` removal; QR reference removal (ICV kept); `Signature` removal; no-op on clean document |
| `services/api_service_test.dart` | 169 | Mockito mock injection; `sendClear` 200 response; `DioException` returns error response; `sendReport` 200; `sendCsr` throws on invalid format; `sendCsr` throws on missing data field; `sendCsr` returns certificate string on success |
| `core/invoice_item_test.dart` | 59 | Correct total calculation; zero quantity; fractional prices; field mutability |
| `core/qr_generator_test.dart` | 86 | Deterministic output for identical inputs; valid Base64 output; sensitivity to input changes |

```bash
# Run all tests
flutter test

# Run a specific file
flutter test test/services/api_service_test.dart

# Run with coverage (requires lcov)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 24. Dependencies

### Runtime Dependencies

| Package | Purpose |
|---|---|
| `provider ^6.0.5` | App-wide state management via `ChangeNotifier` |
| `dio ^5.9.0` | HTTP client with interceptor support |
| `xml ^6.5.0` | XML parsing and DOM building |
| `uuid ^3.0.7` | UUID v4 generation for invoice IDs |
| `crypto ^3.0.2` | SHA-256 hashing for invoice chaining |
| `pointycastle ^4.0.0` | Cryptographic primitives |
| `basic_utils ^5.8.2` | X.509 / PKI utilities |
| `x509 ^0.2.4+3` | X.509 certificate parsing |
| `qr_flutter ^4.1.0` | QR code rendering widget |
| `sqflite ^2.2.8+4` | SQLite for mobile |
| `sqflite_common_ffi` | SQLite via FFI for desktop |
| `path_provider ^2.1.5` | Platform-specific directory resolution |
| `path ^1.9.1` | Path string manipulation |
| `http ^1.2.0` | Supplementary HTTP utilities |

### Dev Dependencies

| Package | Purpose |
|---|---|
| `flutter_test` | Flutter testing framework |
| `mockito ^5.4.4` | Mock generation for unit tests |
| `build_runner ^2.4.15` | Code generation (Mockito mocks via `dart run build_runner build`) |
| `meta ^1.9.1` | `@visibleForTesting` annotations |
| `flutter_lints ^5.0.0` | Dart lint rules |

---

*STC Client · Technical Documentation · v5 · [github.com/sameryousif/stc-client](https://github.com/sameryousif/stc-client)*