# Install Flutter and Get Preview Link

## Step 1: Install Flutter

Run this command:
```bash
sudo snap install flutter --classic
```

## Step 2: Verify Installation

```bash
flutter doctor
```

## Step 3: Get Preview Link

Once Flutter is installed, run:

```bash
cd /home/bu2lo/LOCOL
./run_preview.sh
```

OR manually:

```bash
cd /home/bu2lo/LOCOL
flutter pub get
flutter config --enable-web
flutter run -d chrome --web-port=8080
```

**Your preview link will be**: `http://localhost:8080`

## Alternative: Build and Serve

```bash
flutter build web
cd build/web
python3 -m http.server 8080
```

Then open: `http://localhost:8080`

