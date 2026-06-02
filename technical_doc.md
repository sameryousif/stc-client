# STC Client Technical Documentation

This document describes the current implementation of STC Client: its runtime architecture, signing pipeline, API contract, local persistence, and testing surface.

## System Overview

STC Client is a Flutter app that prepares and submits STC-compatible electronic invoices. The core workflow is:

1. Generate an RSA-2048 private key and DER-encoded CSR with OpenSSL.
2. Submit the CSR to the enrollment endpoint and persist the returned certificate as DER.
3. Build a UBL invoice XML document from invoice form data.
4. Add invoice-chain metadata: ICV and previous invoice hash.
5. Canonicalize XML with the bundled `stc-cli` tool.
6. Build XAdES `SignedProperties` and `SignedInfo` sections.
7. Sign canonical `SignedInfo` with RSA-SHA256 using the merchant private key.
8. Inject the XAdES signature into `ext:UBLExtensions`.
9. Generate and inject the QR `AdditionalDocumentReference`.
10. Submit the signed invoice DTO to the clearance or reporting endpoint.
11. Store successful invoice history locally for future ICV/hash chaining.

## Runtime Startup

Startup is defined in `lib/main.dart`.

```text
main()
  WidgetsFlutterBinding.ensureInitialized()
  sqfliteFfiInit()
  databaseFactory = databaseFactoryFfi
  ToolPaths.ensureToolsReady()
  create FileService
  create CertEnrollService
  create InvoicePrepService
  runApp(MultiProvider(...))
```

Registered providers:

| Provider | Dependency | Purpose |
|---|---|---|
| `CertificateProvider` | `CertEnrollService` | Tracks certificate validity and enrollment state. |
| `InvoiceProvider` | `InvoicePrepService` | Manages invoice generation, DTO generation, clearance, and reporting state. |

The default route is `SandboxPage`. Named routes are registered for `/invoice` and `/enrollment` in `lib/app.dart`.

## Architecture

The codebase follows a pragmatic layered structure.

```text
Presentation -> Application Controllers -> Providers/Services -> Core/Models/Utils
```

| Layer | Path | Responsibility |
|---|---|---|
| Presentation | `lib/presentation/` | Flutter screens and widgets. Renders UI and forwards actions. |
| Application | `lib/application/controllers/` | Per-screen coordination and form state. |
| State | `lib/state/providers/` | App-wide `ChangeNotifier` state for certificate and invoice workflows. |
| Services | `lib/services/` | I/O, subprocesses, HTTP, file persistence, SQLite processing. |
| Core | `lib/core/` | Invoice items, XML building, QR encoding, certificate helpers, enrollment value objects. |
| Models | `lib/models/` | Supplier and customer data objects. |
| Utils | `lib/utils/paths/` | Platform-aware runtime paths for generated files and tools. |

The implementation is not fully pure by layer: for example, some certificate helpers in `core/certificate` call OpenSSL through `Process.run`. Treat the table as the intended organization rather than a strict dependency boundary.

## Important Files

| File | Purpose |
|---|---|
| `lib/main.dart` | Initializes Flutter, SQLite FFI, tool extraction, and providers. |
| `lib/app.dart` | Defines `MaterialApp`, default screen, and routes. |
| `lib/services/api_service.dart` | Dio client and STC API calls. |
| `lib/services/crypto_service.dart` | OpenSSL key and CSR generation. |
| `lib/services/enrollment_service.dart` | CSR generation orchestration and local enrollment file loading. |
| `lib/services/certificateEnrollService.dart` | Certificate enrollment call and PEM-to-DER persistence. |
| `lib/services/invoicePrepService.dart` | Unsigned invoice creation, canonicalization, XAdES signing, QR injection, DTO creation. |
| `lib/services/invoice_processing_service.dart` | SQLite invoice history, hash processing, cleared invoice saving. |
| `lib/core/invoice/xml_generator.dart` | UBL XML generation and XAdES XML fragment builders. |
| `lib/core/qr/qr_generator.dart` | TLV QR Base64 generation. |
| `lib/core/certificate/cert_info.dart` | Certificate issuer, serial, and subject extraction through OpenSSL. |
| `lib/utils/paths/app_paths.dart` | Application data paths. |
| `lib/utils/paths/tools_paths.dart` | Native tool path resolution and asset extraction. |

## Certificate Enrollment

### Subject Model

`EnrollmentSubject` maps form input to X.509 distinguished-name fields:

| Field | OpenSSL Subject Key |
|---|---|
| `cn` | `CN` |
| `on` | `O` |
| `ou` | `OU` |
| `c` | `C` |
| `st` | `ST` |
| `l` | `L` |
| `serialNumber` | `serialNumber` |

### CSR Generation

`EnrollmentController.generateCsr()` calls `EnrollmentService.generateCsr()`, which delegates to `CryptoService.generateKeyAndCsr()`.

OpenSSL commands:

```bash
openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048
openssl req -new -key private_key.pem -out csr.der -subj <subject> -outform DER
```

If the subject map is empty, the current fallback subject is:

```text
/C=SD/ST=Khartoum/L=Khartoum/O=Organization/CN=My.Company.com/serialNumber=5003
```

Generated files:

| File | Format | Source |
|---|---|---|
| `private_key.pem` | PEM | OpenSSL `genpkey` output. |
| `csr.der` | DER | OpenSSL `req -outform DER` output. |

### Certificate Enrollment

`CertEnrollService.enrollCertificate()` first checks `FileService.isCertificateStillValid()`. That check is currently file-age based: certificates newer than `maxDays` are considered valid. It does not parse the certificate `notBefore`/`notAfter` fields.

If enrollment proceeds, `ApiService.sendCsr()` posts:

```json
{
  "csr": "<base64 DER CSR>",
  "token": "<enrollment token>"
}
```

Expected success shape:

```json
{
  "data": {
    "certificate": "<PEM certificate>"
  }
}
```

The PEM certificate is stripped of headers/whitespace, Base64-decoded to DER, and saved as `merchant.der`.

## Invoice Generation

Invoice UI state is managed by `InvoiceFormController`.

Default invoice metadata:

| Field | Default |
|---|---|
| `invoiceNumber` | UUID v4 |
| `invoiceDate` | Current time |
| `invoiceType` | `380` |
| `currencyCode` | `SDG` |

`InvoiceFormController` calculates totals from `InvoiceItem.total` and each item's `taxRate`:

```text
subtotal = sum(quantity * unitPrice)
taxTotal = sum(item.total * taxRate / 100)
grandTotal = subtotal + taxTotal
```

`InvoicePrepService.generateUnsignedInvoice()` creates a UUID, issue date/time, ICV, previous hash, and then calls `generateUBLInvoice()`.

### ICV and Previous Invoice Hash

The invoice counter value and previous invoice hash come from `InvoiceProcessingService`.

```text
entityId = certificate serialNumber from subject
lastInvoice = latest local SQLite invoice for entityId
icv = lastInvoice.icv + 1, or 1 if none exists
previousInvoiceHash = lastInvoice.hash, or Base64(SHA-256("0")) if none exists
```

The current query is by `entityId`. Although the method name includes `ByType`, the current implementation does not filter by clearance/reporting type.

### UBL XML Content

`generateUBLInvoice()` builds a UBL invoice with:

| Section | Content |
|---|---|
| Namespaces | UBL, CAC, CBC, DS, EXT, SAC, SIG, XAdES namespaces. |
| `cbc:ProfileID` | `clearance` or `reporting` from `InvoicePrepService`. |
| `cbc:ID` | Invoice number. |
| `cbc:UUID` | Generated UUID v4. |
| `cbc:IssueDate` / `IssueTime` | Current local date/time split from `DateTime.now()`. |
| `cbc:InvoiceTypeCode` | Current hardcoded value `388` with `name="0100000"`. |
| Currency | `SDG` for document and tax currency. |
| ICV reference | `AdditionalDocumentReference` with `ID=ICV`. |
| PIH reference | `AdditionalDocumentReference` with `ID=PIH`. |
| Supplier/customer | Postal address, tax scheme, legal entity, contact details. |
| Totals | Tax total and legal monetary total. |
| Lines | One `cac:InvoiceLine` per item. |

Implementation note: XML line tax generation currently uses a fixed `0.15` rate inside `generateUBLInvoice()`, while controller totals use each item's `taxRate`.

## XAdES Signing Pipeline

The main signing entry point is `InvoicePrepService.generateAndSignInvoice()`.

```text
generateAndSignInvoice()
  generateUnsignedInvoice()
  write input.xml
  runCanonicalizationCli(input.xml, output.xml)
  injectXadesSignature(invoice, merchant.der)
  save invoices/invoice_<number>.xml
  addQrToInvoice(...)
  return signed invoice path
```

### Canonicalization

`runCanonicalizationCli(inputPath, outputPath)` copies the input file into a temporary directory, runs the extracted `stc-cli`, verifies `output.xml`, and copies the canonicalized output back to the requested path.

Command shape:

```bash
stc-cli input.xml output.xml
```

The CLI is invoked with `workingDirectory` set to the temporary directory.

### Signature Construction

`injectXadesSignature()` performs these steps:

1. Hash the canonical unsigned invoice at `output.xml` with SHA-256 and Base64-encode it.
2. Extract certificate issuer and serial number with OpenSSL.
3. Build `xades:SignedProperties` with signing time, certificate digest, issuer name, and serial number.
4. Write only the `xades:SignedProperties` element to `signed_props.xml` with required namespaces.
5. Canonicalize `signed_props.xml` and hash it.
6. Build `ds:SignedInfo` with references to the invoice hash and signed properties hash.
7. Write `signedInfo.xml` with the required `ds` namespace and canonicalize it.
8. Sign canonical `signedInfo.xml` with OpenSSL using RSA-SHA256.
9. Base64-encode the raw signature bytes.
10. Base64-encode the DER certificate.
11. Build the final `ds:Signature` element.
12. Replace the invoice's existing `ext:UBLExtensions` with a new signed extension block.

Signing command:

```bash
openssl dgst -sha256 -sign private_key.pem -out signedInfo.sig signedInfo.xml
```

### Certificate Details

Issuer extraction:

```bash
openssl x509 -inform DER -in merchant.der -noout -issuer -nameopt RFC2253
```

Serial extraction:

```bash
openssl x509 -inform DER -in merchant.der -noout -serial
```

The serial is returned as hex by OpenSSL and converted to decimal for XAdES.

## QR Generation

`generateQr()` in `lib/core/qr/qr_generator.dart` builds a TLV byte stream and Base64-encodes it.

| Tag | Value | Encoding |
|---|---|---|
| `1` | Seller name | UTF-8 |
| `2` | VAT/TIN number | UTF-8 |
| `3` | Issue date | `DateTime.toIso8601String()` UTF-8 |
| `4` | Invoice total | Two-decimal string UTF-8 |
| `5` | VAT total | Two-decimal string UTF-8 |
| `6` | XML hash | UTF-8 |
| `7` | Signature | Raw bytes |
| `8` | Certificate | Raw DER bytes |

Length encoding supports short form, `0x81`, and `0x82` forms. Values over 65,535 bytes throw an exception.

`addQrToInvoice()` injects the QR as a `cac:AdditionalDocumentReference` with `cbc:ID` equal to `QR`.

## API Service

`ApiService` is a singleton-style static wrapper around Dio.

Base URL:

```dart
static const String _baserUrl = 'https://stc-server.onrender.com';
```

Dio options:

| Option | Value |
|---|---|
| `connectTimeout` | 20 seconds |
| `receiveTimeout` | 20 seconds |
| `validateStatus` | Any status `< 600` |
| Headers | `Content-Type: application/json`, `Accept: application/json` |

Debug builds log requests, responses, and Dio errors through the configured interceptor.

### Endpoints

| Method | Endpoint | Function | Notes |
|---|---|---|---|
| `POST` | `/enroll` | `sendCsr()` | Sends Base64 CSR and token. |
| `POST` | `/enroll` | `sendCsrSandbox()` | Sends raw sandbox CSR body. |
| `POST` | `/clear` | `sendClear()` | Sends signed invoice DTO. Sandbox mode adds `X-Sandbox-Mode: true`. |
| `POST` | `/report` | `sendReport()` | Sends signed invoice DTO. Sandbox mode adds `X-Sandbox-Mode: true`. |

Clear/report DTO shape:

```json
{
  "uuid": "<invoice number currently passed as uuid>",
  "invoice_hash": "<Base64 SHA-256 hash>",
  "invoice": "<Base64 signed XML>"
}
```

`sendSignedInvoice()` builds this DTO from the current signed XML and the hash of `work/output.xml`.

## Invoice Response Processing

`InvoiceProvider.clearInvoice()` and `InvoiceProvider.reportInvoice()` handle successful production responses differently.

### Clearance

On HTTP 202:

1. Read `response.data.data.cleared_invoice`.
2. Extract `entityId` from the merchant certificate subject `serialNumber`.
3. Decode and save the cleared invoice XML under `cleared/`.
4. Remove `UBLExtensions`, `Signature`, and QR `AdditionalDocumentReference` from a working copy.
5. Canonicalize the stripped XML.
6. Hash the canonical XML.
7. Insert invoice metadata into SQLite.

### Reporting

On HTTP 200:

1. Base64-encode the locally signed XML.
2. Extract `entityId` from the merchant certificate subject `serialNumber`.
3. Remove signature/QR sections from a working copy.
4. Canonicalize and hash the stripped XML.
5. Insert invoice metadata into SQLite.

Sandbox submissions return the HTTP status and response body without local response processing.

## SQLite Storage

Database file:

```text
invoices.db
```

The path is resolved through `sqflite`'s `getDatabasesPath()`.

Schema:

```sql
CREATE TABLE invoices(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entityId TEXT,
  icv INTEGER,
  base64Invoice TEXT,
  type TEXT,
  hash TEXT,
  createdAt TEXT
)
```

Current save behavior inserts:

| Column | Value |
|---|---|
| `entityId` | Certificate subject serial number. |
| `base64Invoice` | Submitted or cleared invoice Base64. |
| `hash` | Hash of stripped canonical invoice XML. |
| `icv` | Next local ICV. |
| `createdAt` | Current ISO-8601 timestamp. |

Implementation note: the `type` column exists in the schema but is not currently populated by `_saveInvoice()`.

## Runtime File Paths

`AppPaths` creates an `stc_client` folder inside `getApplicationSupportDirectory()`.

| Path Method | File / Directory | Purpose |
|---|---|---|
| `appDir()` | `stc_client/` | Root app data folder. |
| `privateKeyPath()` | `private_key.pem` | Merchant private key. |
| `csrPath()` | `csr.der` | Certificate signing request. |
| `certPath()` | `merchant.der` | Merchant certificate. |
| `invoicesDir()` | `invoices/` | Signed local invoices. |
| `clearedDir()` | `cleared/` | Cleared invoice copies. |
| `workingDir()` | `work/` | Temporary XML signing artifacts. |
| `inputXmlPath()` | `work/input.xml` | Unsigned invoice XML. |
| `outputXmlPath()` | `work/output.xml` | Canonical unsigned invoice XML. |
| `signedPropsPath()` | `work/signed_props.xml` | Canonicalized signed properties. |
| `signedInfoPath()` | `work/signedInfo.xml` | Canonicalized signed info. |
| `tempInvoicePath()` | `work/temp_invoice.xml` | Post-submission processing temp file. |

`ToolPaths` creates a sibling `tools/` directory under the application support directory.

| Platform | Tool Behavior |
|---|---|
| Windows | Extracts `assets/tools/windows/stc-cli.exe` and `assets/tools/windows/openssl.exe`. |
| Non-Windows | Extracts `assets/tools/linux/stc-cli`, applies `chmod +x`, and uses `/usr/bin/openssl`. |

## Tests

The test suite covers the most isolated parts of the app:

| Area | Files |
|---|---|
| QR generation | `test/core/qr_generator_test.dart`, `test/widget_test.dart` |
| Invoice item calculations | `test/core/invoice_item_test.dart`, `test/widget_test.dart` |
| Invoice form totals and maps | `test/core/invoice_controller_test.dart` |
| XML section removal | `test/services/invoice_processing_test.dart`, `test/widget_test.dart` |
| API behavior with mocked Dio | `test/services/api_service_test.dart` |
| XAdES XML fragment generation | `test/core/xml_generator_xades_test.dart` |
| UBL XML structure | `test/widget_test.dart` |

Run all tests:

```bash
flutter test
```

Run a single test file:

```bash
flutter test test/services/api_service_test.dart
```

Regenerate mocks:

```bash
dart run build_runner build
```

## Dependencies

Primary runtime packages:

| Package | Purpose |
|---|---|
| `provider` | App-wide state management. |
| `dio` | HTTP client. |
| `xml` | XML DOM building and parsing. |
| `uuid` | Invoice and subject UUID generation. |
| `crypto` | SHA-256 hashing. |
| `qr_flutter` | QR rendering. |
| `sqflite` / `sqflite_common_ffi` | SQLite on mobile/desktop. |
| `path_provider` | Platform support-directory resolution. |
| `path` | Path joining/manipulation. |
| `basic_utils`, `pointycastle`, `x509` | Certificate/crypto support utilities. |

Primary dev packages:

| Package | Purpose |
|---|---|
| `flutter_test` | Flutter test framework. |
| `mockito` | API service mocks. |
| `build_runner` | Mock code generation. |
| `flutter_lints` | Recommended lint set. |

## Known Implementation Notes

- The API base URL is hardcoded and not environment-driven.
- Certificate validity currently checks file age, not certificate expiration metadata.
- The invoice DTO `uuid` is built from `currentInvoiceNumber`, while UBL XML also contains a separately generated UUID.
- `InvoiceProcessingService.getLastInvoiceForEntityByType()` does not currently filter by invoice type.
- The SQLite `type` column is defined but not populated.
- `generateUBLInvoice()` calculates XML VAT with a fixed 15% rate, while the form controller supports per-item tax rates.
- Non-Windows tool resolution extracts the Linux `stc-cli` asset, so macOS and mobile signing support should be validated before use.
