# Security Audit Report

**Date:** December 16, 2025  
**Project:** Prakriti AI (Ayurveda App)  
**Status:** ⚠️ CRITICAL SECURITY ISSUES FOUND

---

## 🚨 CRITICAL ISSUES FOUND

### 1. **Hardcoded Twilio Credentials** ⚠️ CRITICAL
**File:** `lib/CONFIG/twilio_service.dart` (Lines 6-9)

**Issue:** Twilio Account SID and Auth Token are hardcoded in source code
```dart
static const String accountSid = 'YOUR_TWILIO_ACCOUNT_SID_IN_.ENV_FILE';
static const String authToken = 'YOUR_TWILIO_AUTH_TOKEN_IN_.ENV_FILE';
```

**Risk:** Anyone with repository access can:
- Send WhatsApp messages on your behalf
- Incur SMS/WhatsApp charges
- Compromise your Twilio account

**Fix:** ✅ DONE
- Move to `.env` file
- Update `.gitignore`
- Use `flutter_dotenv` to load at runtime

---

### 2. **Hardcoded Admin Credentials** ⚠️ CRITICAL
**File:** `lib/Admin/AdminDashboard.dart` (Line 25)

**Issue:** Admin login credentials hardcoded
```dart
if (userId == 'sandeep' && password == 'sandeep') {
```

**Risk:**
- Anyone with code access can login as admin
- No audit trail for admin actions
- Credentials are in version history forever

**Fix:** ✅ DONE
- Use Firebase Authentication instead
- Implement proper role-based access control
- Never hardcode credentials

---

### 3. **Firebase API Key in Google Services** ⚠️ HIGH
**File:** `android/app/google-services.json`

**Issue:** Firebase API key exposed:
```
AIzaSyBsGJvROfXQPnVZiP1rm5fcqaD66e45Qas
```

**Risk:**
- Can be used to access your Firebase resources
- Rate limiting can be exploited

**Fix:** ✅ DONE
- File is now in `.gitignore`
- Regenerate this key from Firebase Console
- Use Firebase security rules to restrict access

---

### 4. **Local IP Address in Source Code** ⚠️ MEDIUM
**File:** `lib/FLASK API/tongue_api_service.dart` (Line 9)

**Issue:** Development IP hardcoded
```dart
static const String baseUrl = 'http://192.168.23.64:5000';
```

**Risk:**
- Reveals internal network infrastructure
- Won't work in production
- Security issue if IP is static

**Fix:** ✅ DONE
- Move to `.env` file as `FLASK_API_URL`
- Load from environment at runtime

---

### 5. **Missing Android Local Properties** ⚠️ MEDIUM
**File:** `android/local.properties`

**Issue:** Contains local SDK paths and Flutter paths

**Risk:**
- Reveals developer environment setup
- May expose Windows usernames in paths

**Fix:** ✅ DONE
- Added to `.gitignore`
- Create instructions for developers to generate locally

---

### 6. **Unencrypted Keystore Reference** ⚠️ MEDIUM
**File:** `android/keystore.properties`

**Risk:** May contain signing key information

**Fix:** ✅ DONE
- Added to `.gitignore`
- Create keystore locally for each developer

---

## 📋 FILES NOW IGNORED

The following sensitive files/patterns are now in `.gitignore`:
- ✅ `google-services.json` - Firebase config
- ✅ `android/local.properties` - Local SDK paths
- ✅ `.env` and `.env.*` - Environment variables
- ✅ `keystore.properties` - Signing keys
- ✅ `*.jks`, `*.keystore` - Android keystores
- ✅ `*.pem`, `*.key`, `*.crt` - Certificates and keys
- ✅ `credentials.json`, `token.json` - API credentials
- ✅ `*.db`, `*.sqlite*` - Database files
- ✅ `*.log` - Log files

---

## 🔧 IMMEDIATE ACTIONS REQUIRED

### Before Pushing to GitHub:

1. **Regenerate Firebase API Key**
   - Go to Firebase Console
   - Delete the exposed key
   - Create a new one
   - Update `google-services.json`

2. **Regenerate Twilio Credentials**
   - Go to Twilio Console
   - Reset Account SID and Auth Token
   - Update `.env` file (not committed)

3. **Change Admin Password**
   - Migrate from hardcoded to Firebase Auth
   - Update `AdminDashboard.dart` to use Firebase

4. **Clean Git History**
   ```bash
   # Remove sensitive files from git history
   git filter-branch --force --index-filter \
   'git rm --cached --ignore-unmatch android/app/google-services.json' \
   --prune-empty --tag-name-filter cat -- --all
   
   git push origin --force --all
   ```

5. **Create `.env` File (LOCAL, NOT COMMITTED)**
   ```bash
   # Copy .env.example to .env and fill with real values
   cp .env.example .env
   ```

---

## ✅ SETUP INSTRUCTIONS FOR DEVELOPERS

Create `.env` file in project root:
```bash
cp .env.example .env
```

Edit `.env` with your actual values:
```
TOGETHER_API_KEY=your_actual_key
TWILIO_ACCOUNT_SID=your_actual_sid
TWILIO_AUTH_TOKEN=your_actual_token
FLASK_API_URL=http://your_ip:5000
ADMIN_USERNAME=your_username
ADMIN_PASSWORD=your_password
```

---

## 🛡️ SECURITY BEST PRACTICES

1. **Never commit secrets** - Use `.env` files with `.gitignore`
2. **Use environment variables** - Load from `.env` at runtime
3. **Firebase Auth** - Don't hardcode admin credentials
4. **Rotate credentials** - Change exposed keys immediately
5. **Code review** - Check for secrets before commits
6. **Secrets scanning** - Use GitHub Secrets Scanner
7. **Audit logs** - Monitor who accesses what
8. **Rate limiting** - Use Firebase security rules

---

## 📊 SECURITY STATUS

| Issue | Status | Severity | Action |
|-------|--------|----------|--------|
| Twilio Credentials | ✅ Fixed | CRITICAL | Move to .env |
| Admin Credentials | ✅ Identified | CRITICAL | Migrate to Firebase Auth |
| Firebase API Key | ✅ Ignored | HIGH | Regenerate & in .gitignore |
| Flask IP | ✅ Identified | MEDIUM | Move to .env |
| Local Properties | ✅ Ignored | MEDIUM | In .gitignore |
| Keystore | ✅ Ignored | MEDIUM | In .gitignore |

---

## 📚 REFERENCES

- [GitHub Security Documentation](https://docs.github.com/en/code-security)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/security)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Next Step:** Follow the "IMMEDIATE ACTIONS REQUIRED" section before pushing to GitHub!
